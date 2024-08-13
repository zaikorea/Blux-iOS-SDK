//
//  ColdStartNotificationManager.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
class ColdStartNotificationManager {
    static var coldStartNotification: BluxNotification?
    
    /// Set coldStartNotification in launchOptions
    static func setColdStartNotification(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let bluxNotification = BluxNotification.getBluxNotificationFromLaunchOptions(launchOptions: launchOptions) {
            self.coldStartNotification = bluxNotification
        }
    }
    
    /// Check and execute coldStartNotification
    static func process() {
        guard let notification = coldStartNotification else {
            return
        }
        
        if (UIApplication.shared.applicationState == .background) {
            // When called in the background, the app is not turned on
            // Set coldStartNotification to nil to be clicked in notificationCenter
            self.coldStartNotification = nil
        } else {
            // If it is not in the background state, process clicked and keep coldStartNotification to avoid duplicate processing in notificationCenter
            EventService.createPushOpened(notification: notification)
        }
    }
}
