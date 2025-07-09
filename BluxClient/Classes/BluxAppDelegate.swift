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
    
    @objc public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        BluxClient.hasPermissionForNotifications { hasPermission in
            if (!hasPermission) {
                Logger.verbose("No permission for notifications.")
                return
            }
            
            let pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            
            if let _ = SdkConfig.deviceIdInUserDefaults {
                let body = DeviceService.getBluxDeviceInfo()
                body.pushToken = pushToken
                
                DeviceService.updatePushToken(body: body)
            }
        }
    }
}
