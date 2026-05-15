import Foundation
import UIKit
import UserNotifications

@objc open class NotificationReceivedEvent: NSObject {
    @objc public var notification: BluxNotification

    /// completionHandler 호출 직후 한 번 호출. wrapper가 자기 dict cleanup에 사용.
    @objc public var onComplete: (() -> Void)?

    private var completionHandler: ((UNNotificationPresentationOptions) -> Void)?
    private var fallbackWorkItem: DispatchWorkItem?

    private static let fallbackTimeout: TimeInterval = 20

    init(notification: BluxNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.notification = notification
        self.completionHandler = completionHandler
        super.init()
        scheduleFallback()
    }

    @objc public func toDictionary() -> [String: Any] {
        return [
            "notification": notification.toDictionary(),
        ]
    }

    @objc public func display() {
        Logger.verbose("Notification received: \(notification)")
        complete(with: [.alert, .sound])
    }

    /// 시스템 알림을 표시하지 않음 (인앱 UI로만 처리하는 경우 등).
    /// display()/suppress() 둘 다 미호출이면 fallback timeout 후 자동 suppress.
    @objc public func suppress() {
        Logger.verbose("Notification suppressed: \(notification.id)")
        complete(with: [])
    }

    private func scheduleFallback() {
        // strong capture: wrapper가 event ref를 일찍 놓아도 fallback이 발화해 completionHandler를 호출한다.
        let workItem = DispatchWorkItem { [self] in
            Logger.verbose("NotificationReceivedEvent fallback timeout: suppressing notification \(notification.id)")
            complete(with: [])
        }
        fallbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fallbackTimeout, execute: workItem)
    }

    // display/suppress/fallback 동시 진입 시 completionHandler 중복 호출 방지 + dispatch 대기 중 self release로 인한 미호출 방지.
    private func complete(with options: UNNotificationPresentationOptions) {
        if Thread.isMainThread {
            finalize(with: options)
        } else {
            DispatchQueue.main.async { [self] in
                finalize(with: options)
            }
        }
    }

    private func finalize(with options: UNNotificationPresentationOptions) {
        guard let handler = completionHandler else { return }
        completionHandler = nil
        fallbackWorkItem?.cancel()
        fallbackWorkItem = nil
        handler(options)
        onComplete?()
        onComplete = nil
    }
}
