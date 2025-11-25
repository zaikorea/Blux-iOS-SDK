//
//  AppDelegate.swift
//  BluxClient
//
//  Created by dongjoocha on 05/21/2024.
//  Copyright (c) 2024 dongjoocha. All rights reserved.
//

import BluxClient
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    let applicationId = "66fac6b03e71e06835703c25"
    let apiKey = "Is5r2sK-HBQe4sX343twQopcccevFm0Ci6nu9tA9"

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        BluxClient.setAPIStage("prod")

        BluxClient.initialize(launchOptions, bluxApplicationId: applicationId, bluxAPIKey: apiKey, requestPermissionOnLaunch: true) { error in
            if let error = error {
                Logger.verbose("BluxClient.initialize error: \(error)")
            } else {
                Logger.verbose("BluxClient.initialize success")
                BluxClient.signIn(userId: "luna")
            }
        }

        // Swizzling Disabled
        UNUserNotificationCenter.current().delegate = self

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

    // Swizzling Disabled
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        BluxAppDelegate.shared.application(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
        )
    }
}

// Swizzling Disabled
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        BluxNotificationCenter.shared.userNotificationCenter(
            center, didReceive: response,
            withCompletionHandler: completionHandler
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        BluxNotificationCenter.shared.userNotificationCenter(
            center, willPresent: notification,
            withCompletionHandler: completionHandler
        )
    }
}
