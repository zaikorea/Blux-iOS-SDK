//
// BluxAppDelegate.swift
// BluxClient
//
// Created by Tommy on 6/4/24.
//

import Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
@objc public class BluxAppDelegate: NSObject {
    @objc public static let shared = BluxAppDelegate()

    /// 현재 프로세스에서 받은 APNs 디바이스 토큰을 문자열로 변환한 푸시 토큰입니다.
    /// APNs 등록 콜백 전에는 nil입니다.
    @objc public private(set) var pushToken: String?

    @objc public func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let pushToken = Self.pushTokenString(from: deviceToken)
        self.pushToken = pushToken

        BluxClient.hasPermissionForNotifications { hasPermission in
            if !hasPermission {
                Logger.verbose("No permission for notifications.")
                return
            }

            if let _ = SdkConfig.deviceIdInUserDefaults {
                let body = DeviceService.getBluxDeviceInfo()
                body.pushToken = pushToken

                DeviceService.updatePushToken(body: body)
            }
        }
    }

    static func pushTokenString(from deviceToken: Data) -> String {
        deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
