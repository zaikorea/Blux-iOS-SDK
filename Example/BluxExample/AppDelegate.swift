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

    let applicationId = "69327634beb1da48e4278ed6"
    let apiKey = "RicSIM9zJTFZawchFbl12et6R_u6aLkgEwERnk8t"

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        BluxClient.setAPIStage("stg")

        BluxClient.initialize(launchOptions, bluxApplicationId: applicationId, bluxAPIKey: apiKey, requestPermissionOnLaunch: true) { error in
            if let error = error {
                Logger.verbose("BluxClient.initialize error: \(error)")
            } else {
                Logger.verbose("BluxClient.initialize success")
                BluxClient.signIn(userId: "team")
            }
        }

        // Custom HTML 인앱 액션 핸들러 등록
        _ = BluxClient.addInAppCustomActionHandler { actionId, data in
            // dismiss 애니메이션 완료 후 alert 표시 (0.3초 지연)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let dataString = data.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                let message = "actionId: \(actionId)\ndata: {\(dataString)}"

                let alert = UIAlertController(
                    title: "Custom Action",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController {
                        topVC = presented
                    }
                    topVC.present(alert, animated: true)
                }
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
