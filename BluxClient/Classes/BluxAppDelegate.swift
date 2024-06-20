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
        swizzleMethod(
            originalSelector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)),
            swizzledSelector: #selector(self.applicationDidBecomeActive(_:)),
            in: UIApplication.shared.delegate
        )
        swizzleMethod(
            originalSelector: #selector(UIApplicationDelegate.applicationWillResignActive(_:)),
            swizzledSelector: #selector(self.applicationWillResignActive(_:)),
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
            
            // Convert token to string
            let prevPushToken = SdkConfig.pushTokenInUserDefaults
            let pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            Logger.verbose("APNs device token: \(pushToken)")
            
            // It is divided into activate and register depending on the presence of deviceId
            if let _ = SdkConfig.deviceIdInUserDefaults, pushToken != prevPushToken {
                let body = DeviceService.getBluxDeviceInfo()
                body.pushToken = pushToken
                
                DeviceService.update(body: body) { _ in
                    SdkConfig.pushTokenInUserDefaults = pushToken
                }
            }
        }
    }
    
    @objc public func applicationDidBecomeActive(_ application: UIApplication) {
        if let userDefaults = UserDefaults(suiteName: SdkConfig.bluxSuiteName) {
            userDefaults.set(true, forKey: "isAppInForeground")
        }
    }
    
    @objc public func applicationWillResignActive(_ application: UIApplication) {
        if let userDefaults = UserDefaults(suiteName: SdkConfig.bluxSuiteName) {
            userDefaults.set(false, forKey: "isAppInForeground")
        }
    }
}
