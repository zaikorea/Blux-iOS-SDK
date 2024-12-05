import Foundation
import UIKit
import WebKit

@available(iOSApplicationExtension, unavailable)
class InappService {
   private static var webViewQueue: [() -> Void] = []
   private static var isWebViewPresented = false

   public static func handleInappEvent(_ events: [Event]) {
      Logger.verbose("INAPP: Handling inapp event")

      let device = DeviceService.getBluxDeviceInfo()
      guard
         let deviceId = device.deviceId,
         let bluxId = device.bluxId,
         let clientId = SdkConfig.clientIdInUserDefaults
      else {
         return
      }

      let event = InappDispatchRequest(
         events: events, bluxUserId: bluxId, deviceId: deviceId
      )

      HTTPClient.shared.post(
         path: "/applications/" + clientId + "/inapps/dispatch",
         body: event
      ) { (response: InappDispatchResponse?, error) in
         if let error = error {
            Logger.error(
               "INAPP: Failed to get inapp dispatch response - \(error)")
            return
         }

         if let inappDispatchResponse = response {
            switch inappDispatchResponse {
            case .display(
               let notificationId,
               let htmlString,
               let inappId,
               let baseUrl
            ):
               Logger.verbose(
                  "INAPP: Dispatch response received. \(inappId) \(baseUrl)"
               )
               queueInappWebview(
                  notificationId,
                  htmlString,
                  inappId,
                  URL(string: baseUrl)!
               )
            case .noDisplay:
               Logger.verbose(
                  "INAPP: Inapp should not be displayed."
               )
            }
         }
      }
   }

   private static func queueInappWebview(
      _ notificationId: String,
      _ htmlString: String,
      _ inappId: String,
      _ baseURL: URL
   ) {
      let presentWebView = {
         presentInappWebview(notificationId, htmlString, inappId, baseURL)
      }

      webViewQueue.append(presentWebView)
      processWebViewQueue()
   }

   private static func processWebViewQueue() {
      guard !isWebViewPresented, let nextWebView = webViewQueue.first else {
         return
      }

      isWebViewPresented = true
      webViewQueue.removeFirst()
      nextWebView()
   }

   private static func dismissWebView(
      _ webviewController: WebViewController,
      completion: @escaping () -> Void = {}
   ) {
      webviewController.dismiss(animated: false) {
         isWebViewPresented = false
         processWebViewQueue()
         completion()
      }
   }

   private static func presentInappWebview(
      _ notificationId: String,
      _ htmlString: String,
      _ inappId: String,
      _ baseURL: URL
   ) {
      DispatchQueue.main.async {
         if let dateToHide = UserDefaults.standard.string(forKey: inappId) {
            let dateToHideDate = ISO8601DateFormatter().date(from: dateToHide)
            if let dateToHideDate = dateToHideDate {
               if dateToHideDate > Date() {
                  Logger.verbose(
                     "INAPP: Inapp with inapp_id \(inappId) is hidden.")
                  isWebViewPresented = false
                  processWebViewQueue()
                  return
               }
            }
         }

         if let topController = UIViewController.getTopViewController() {
            let webviewController = WebViewController(
               content: .htmlString(
                  html: htmlString,
                  baseURL: baseURL
               )
            )

            webviewController.addMessageHandler(
               for: "hide",
               handler: { data in
                  if let daysToHide = data["days_to_hide"] as? Int {
                     if daysToHide > 0 {
                        // 오늘 날짜에서 daysToHide 만큼 더한 날짜를 저장
                        let dateToHide = Calendar.current.date(
                           byAdding: .day, value: daysToHide, to: Date()
                        )

                        if let dateToHide = dateToHide {
                           let dateFormatter = ISO8601DateFormatter()
                           let dateToHideString = dateFormatter.string(
                              from: dateToHide
                           )

                           UserDefaults.standard.set(
                              dateToHideString, forKey: inappId
                           )
                        }
                     }
                  }
                  dismissWebView(webviewController)
               }
            )
            webviewController.addMessageHandler(
               for: "link",
               handler: { data in
                  if let urlString = data["url"] as? String,
                     let url = URL(string: urlString),
                     let scheme = url.scheme
                  {
                     switch scheme {
                     case "http", "https":
                        EventService.createInappOpened(notificationId)
                        // 기존 웹뷰 닫기
                        dismissWebView(webviewController) {
                           DispatchQueue.main.async {
                              if let topController =
                                 UIViewController.getTopViewController(),
                                 topController.view.window != nil
                              {
                                 // 새로운 웹뷰 표시
                                 let newWebViewController = WebViewController(
                                    content: .url(url))
                                 let navigationController =
                                    UINavigationController(
                                       rootViewController: newWebViewController)
                                 navigationController.modalPresentationStyle =
                                    .fullScreen

                                 topController.present(
                                    navigationController, animated: true,
                                    completion: nil
                                 )
                              } else {
                                 Logger.error(
                                    "INAPP: Top view controller is not in the window hierarchy."
                                 )
                              }
                           }
                        }
                     default:
                        dismissWebView(webviewController) {
                           UIApplication.shared.open(url, options: [:])
                        }
                     }
                  }
               }
            )

            EventService.createReceived(notificationId)
            Logger.verbose("INAPP: Presenting inapp webview.")
            webviewController.view.backgroundColor = .clear
            webviewController.modalPresentationStyle = .overFullScreen
            topController.present(
               webviewController, animated: false, completion: nil
            )
         }
      }
   }
}

@available(iOSApplicationExtension, unavailable)
extension UIViewController {
   static func getTopViewController(
      _ baseViewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
   ) -> UIViewController? {
      if let navigationController = baseViewController as? UINavigationController {
         return getTopViewController(navigationController.visibleViewController)
      }

      if let tabBarController = baseViewController as? UITabBarController,
         let selectedViewController = tabBarController.selectedViewController
      {
         return getTopViewController(selectedViewController)
      }

      if let presentedViewController = baseViewController?.presentedViewController {
         return getTopViewController(presentedViewController)
      }

      return baseViewController
   }
}
