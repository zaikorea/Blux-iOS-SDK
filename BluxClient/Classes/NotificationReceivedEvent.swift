import Foundation
import UIKit
import UserNotifications

@objc open class NotificationReceivedEvent: NSObject {
    @objc public var notification: BluxNotification
    private var application: UIApplication
    private var completionHandler: (UNNotificationPresentationOptions) -> Void

    init(_ application: UIApplication, notification: BluxNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.application = application
        self.notification = notification
        self.completionHandler = completionHandler
    }

    @objc public func toDictionary() -> [String: Any] {
        return [
            "notification": notification.toDictionary(),
        ]
    }

    @objc public func display() {
        Logger.verbose("Notification received: \(notification)")
        completionHandler([.alert, .sound])
    }
}
