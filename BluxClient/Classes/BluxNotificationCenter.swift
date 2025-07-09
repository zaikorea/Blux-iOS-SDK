//
//  BluxNotificationCenter.swift
//  BluxClient
//
//  Created by Tommy on 6/4/24.
//

import UserNotifications

@available(iOSApplicationExtension, unavailable)
@objc
public class BluxNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    @objc public static let shared = BluxNotificationCenter()

    /// Called when notification is clicked
    @objc public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { // Called just before the function terminatesg
            completionHandler()
        }

        if let notification =
            BluxNotification.getBluxNotificationFromUNNotificationContent(
                response.notification.request.content)
        {
            if SdkConfig.clientIdInUserDefaults == nil {
                Logger.verbose("No Client ID.")
                ColdStartNotificationManager.coldStartNotification =
                    notification
            } else if ColdStartNotificationManager.coldStartNotification?.id
                == notification.id
            {
                // If the ID of coldStartNotification is the same as notificationId, it stops to avoid duplicate execution
                Logger.verbose("ColdStartNotification exists. Skip didReceive.")
            } else {
                Logger.verbose("Notification clicked.")
                EventService.createPushOpened(notification: notification)
            }

            if let bluxDismissLaunchUrl = Bundle.main.object(
                forInfoDictionaryKey: "blux_dismiss_launch_url") as? Bool,
                bluxDismissLaunchUrl == true
            {
                Logger.verbose(
                    "Launch url was dismissed because blux_dismiss_launch_url in Info.plist is YES."
                )
                return
            }

            if let bluxDismissLaunchUrl = notification.data?[
                "blux_dismiss_launch_url"
            ] as? String,
                bluxDismissLaunchUrl == "true"
            {
                Logger.verbose(
                    "Launch url was dismissed because blux_dismiss_launch_url is true."
                )
                return
            }
            
            

            if let urlString = notification.url,
               let url = URL(string: urlString), let scheme = url.scheme
            {
                switch scheme {
                case "http", "https":
                    presentWebView(url: url)
                default:
                    presentApplication(url: url)
                }
            }
        }
    }

    /// Called when notification is received on the foreground
    @objc public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        if let bluxNotification =
            BluxNotification.getBluxNotificationFromUNNotificationContent(
                notification.request.content)
        {
            if let bluxDismissForegroundNotification = bluxNotification.data?[
                "blux_dismiss_foreground_notification"
            ] as? String,
                bluxDismissForegroundNotification == "true"
            {
                Logger.verbose(
                    "Foreground notification received was dismissed because blux_dismiss_foreground_notification is true."
                )
                return
            }

            let event = NotificationReceivedEvent(
                UIApplication.shared, notification: bluxNotification,
                completionHandler: completionHandler)

            if let handler = EventHandlers.notificationForegroundReceived {
                Logger.verbose(
                    "Handle foreground notification received with registered handler."
                )
                handler(event)
            } else {
                event.display()
            }
        }
    }

    private func presentWebView(url: URL) {
        guard let topViewController = getTopViewController() else {
            return
        }

        // Present WebView (Do not open default browser)
        let webViewController = WebViewController(
            content: .url(url))
        let navigationController = UINavigationController(
            rootViewController: webViewController)
        navigationController.modalPresentationStyle = .fullScreen
        topViewController.present(
            navigationController, animated: true, completion: nil)
    }

    private func getTopViewController(_ baseViewController: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow } )?.rootViewController) -> UIViewController? {
        if let navigationController = baseViewController as? UINavigationController {
            return getTopViewController(navigationController.visibleViewController)
        }

        if let tabBarController = baseViewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return getTopViewController(selectedViewController)
            }
        }

        if let presentedViewController = baseViewController?.presentedViewController {
            return getTopViewController(presentedViewController)
        }

        return baseViewController
    }

    private func presentApplication(url: URL) {
        UIApplication.shared.open(url, options: [:])
    }
}
