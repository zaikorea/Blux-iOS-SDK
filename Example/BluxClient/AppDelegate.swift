//
//  AppDelegate.swift
//  BluxClient
//
//  Created by dongjoocha on 05/21/2024.
//  Copyright (c) 2024 dongjoocha. All rights reserved.
//

import UIKit
import SwiftUI
import BluxClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appState = AppState()
    
    let clientId = "CLIENT ID"
    let apiKey = "SECRET KEY"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        BluxClient.initialize(launchOptions, bluxClientId: clientId, bluxAPIKey: apiKey)
        
        /// Swizzling Disabled
        // UNUserNotificationCenter.current().delegate = self
        
        let contentView = ContentView().environmentObject(appState)
        
        // Create the SwiftUI view that provides the window contents.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }
    
    // Example Deeplink configuration
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//
//        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
//        let host = urlComponents?.host
//        let path = urlComponents?.path
//
//        if host == "product", let productId = path?.components(separatedBy: "/").last {
//            appState.selectedTab = .home
//            appState.selectedProductId = productId
//        } else if host == "tab", let tabIndexString = path?.components(separatedBy: "/").last, let tabIndex = Int(tabIndexString) {
//            if let tab = AppState.Tab(rawValue: tabIndex) {
//                appState.selectedTab = tab
//            }
//        } else {
//            return false
//        }
//
//        return true
//    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {}
    /// Swizzling Disabled
    // func applicationDidBecomeActive(_ application: UIApplication) {
    //     BluxAppDelegate.shared.applicationDidBecomeActive(application)
    // }
    
    func applicationWillResignActive(_ application: UIApplication) {}
    /// Swizzling Disabled
    // func applicationWillResignActive(_ application: UIApplication) {
    //     BluxAppDelegate.shared.applicationWillResignActive(application)
    // }
    
    /// Swizzling Disabled
    // func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //     BluxAppDelegate.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    // }
}

/// Swizzling Disabled
// extension AppDelegate: UNUserNotificationCenterDelegate {
//   func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//       BluxNotificationCenter.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
//   }
//   func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//       BluxNotificationCenter.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
//   }
// }
