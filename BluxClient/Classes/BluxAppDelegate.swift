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
    
    func swizzle() {
        guard !SdkConfig.isSwizzled else {
            Logger.error("Already swizzled.")
            return
        }
        
        Logger.verbose("Start swizzling UIApplicationDelegate methods.")
        swizzleMethod(
            originalSelector: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
            swizzledSelector: #selector(self.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
            in: UIApplication.shared.delegate
        )
        SdkConfig.isSwizzled = true
        Logger.verbose("Swizzling success.")
    }
    
    // MARK: - Swizzler
    
    private func swizzleMethod(originalSelector: Selector, swizzledSelector: Selector, in delegate: UIApplicationDelegate?) {
        guard let delegateClass = object_getClass(delegate) else {
            Logger.error("Failed to get delegate class.")
            return
        }
        
        guard let swizzledMethod = class_getInstanceMethod(BluxAppDelegate.self, swizzledSelector) else {
            Logger.error("Failed to get swizzled method for \(swizzledSelector).")
            return
        }
        
        if let originalMethod = class_getInstanceMethod(delegateClass, originalSelector) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
            Logger.verbose("Exchanged \(originalSelector) with \(swizzledSelector).")
        } else {
            let typeEncoding = method_getTypeEncoding(swizzledMethod)
            let didAddMethod = class_addMethod(delegateClass, originalSelector, method_getImplementation(swizzledMethod), typeEncoding)
            if didAddMethod {
                Logger.verbose("Added \(originalSelector) and set to \(swizzledSelector).")
            } else {
                Logger.error("Failed to add method for \(originalSelector).")
            }
        }
    }
    
    // MARK: - Swizzle Methods
    
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
