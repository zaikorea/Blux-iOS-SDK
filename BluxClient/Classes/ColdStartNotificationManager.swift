//
//  ColdStartNotificationManager.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
class ColdStartNotificationManager {
    static var coldStartNotification: BluxNotification?
    private static var hasProcessedLaunchOptions = false
    private(set) static var lastOpenedNotificationId: String?

    /// launchOptions에서 푸시 알림을 파싱해 coldStartNotification에 저장한다.
    /// WebView 브릿지 환경(네이티브/RN/Flutter)에서는 페이지 전환마다 initialize가 재호출되며 같은 launchOptions가 재전달될 수 있으므로,
    /// 이미 notification을 소비한 이후에는 재진입을 차단한다.
    static func setColdStartNotification(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard !hasProcessedLaunchOptions else { return }
        if let bluxNotification = BluxNotification.getBluxNotificationFromLaunchOptions(launchOptions: launchOptions) {
            coldStartNotification = bluxNotification
        }
    }

    /// launchOptions 경로의 open 처리를 trackOpen(_:)에 위임한다.
    /// Background로 깨어난 경우(silent push 등)에는 사용자 탭이 아니므로 전송하지 않고, 이후 사용자가 탭하면 didReceive가 trackOpen(_:)을 호출한다.
    static func process() {
        guard let notification = coldStartNotification else { return }
        // launchOptions에서 실제로 notification을 소비한 경우에만 재진입 차단 플래그를 세운다.
        // initialize(nil, ...)이 먼저 호출돼도 이후의 initialize(launchOptions, ...)이 정상적으로 처리되도록 하기 위함.
        hasProcessedLaunchOptions = true
        coldStartNotification = nil
        if UIApplication.shared.applicationState == .background { return }
        trackOpen(notification)
    }

    /// push_opened 트래킹의 단일 진입점.
    /// launchOptions 경로(process)와 UN delegate 경로(didReceive) 모두 이 메서드를 통해야 하며, 동일 notification id에 대해 한 번만 전송된다.
    static func trackOpen(_ notification: BluxNotification) {
        guard lastOpenedNotificationId != notification.id else { return }
        lastOpenedNotificationId = notification.id
        notification.trackOpened()
    }

    /// credential 전환(stage/app 변경) 시 상태를 초기화한다.
    /// 보류된 cold-start notification과 소비 플래그를 리셋해 새 credential 아래에서 launchOptions가 다시 처리되도록 한다.
    /// lastOpenedNotificationId는 유지한다. notification id는 서버가 발급하는 전역 유일 ObjectId이므로 credential 경계를 넘어도 dedup 키로 유효하며,
    /// 유지함으로써 didReceive가 먼저 세팅한 dedup 키가 이후 launchOptions 경로에서 지워지는 엣지케이스를 막는다.
    static func reset() {
        coldStartNotification = nil
        hasProcessedLaunchOptions = false
    }
}
