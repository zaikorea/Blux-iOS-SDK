//
//  NotificationReceivedEvent.swift
//  BluxClient
//
//  Created by Tommy on 6/4/24.
//

import Foundation

@objc open class NotificationReceivedEvent: NSObject {
    @objc public var notification: BluxNotification
    private var application: UIApplication
    private var completionHandler: (UNNotificationPresentationOptions) -> Void

    init(_ application: UIApplication, notification: BluxNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.application = application
        self.notification = notification
        self.completionHandler = completionHandler
    }

    @objc public func display() {
        Logger.verbose("Notification received: \(self.notification)")
        self.completionHandler([.alert, .sound])
    }
}
