import Foundation
import Network
import UIKit
import WebKit

@available(iOSApplicationExtension, unavailable)
class InappService {
   private static var webViewQueue: [() -> Void] = []
   private static var isWebViewPresented = false

   private static var dispatchTimer: Timer?
   private static var isDispatching = false

   private static var isAppActive: Bool = true
   private static var isNetworkReachable: Bool = true
   private static var canDispatch: Bool = false
   private static var lifecycleObserversRegistered: Bool = false

   private static var pathMonitor: NWPathMonitor?
   private static let pathMonitorQueue = DispatchQueue(label: "inappservice.network")

   #if swift(>=4.2)
   private static let didBecomeActiveNotification = UIApplication.didBecomeActiveNotification
   private static let willResignActiveNotification = UIApplication.willResignActiveNotification
   private static let didEnterBackgroundNotification = UIApplication.didEnterBackgroundNotification
   #else
   private static let didBecomeActiveNotification = NSNotification.Name.UIApplicationDidBecomeActive
   private static let willResignActiveNotification = NSNotification.Name.UIApplicationWillResignActive
   private static let didEnterBackgroundNotification = NSNotification.Name.UIApplicationDidEnterBackground
   #endif

   #if swift(>=4.2)
   private static let commonMode: RunLoop.Mode = .common
   #else
   private static let commonMode = RunLoopMode.commonModes
   #endif

   public static func enableAutoDispatching() {
      if lifecycleObserversRegistered { return }
      lifecycleObserversRegistered = true

      NotificationCenter.default.addObserver(
         forName: didBecomeActiveNotification,
         object: nil,
         queue: .main
      ) { _ in
         isAppActive = true
         updateCanDispatch()
      }

      NotificationCenter.default.addObserver(
         forName: willResignActiveNotification,
         object: nil,
         queue: .main
      ) { _ in
         isAppActive = false
         updateCanDispatch()
      }

      NotificationCenter.default.addObserver(
         forName: didEnterBackgroundNotification,
         object: nil,
         queue: .main
      ) { _ in
         isAppActive = false
         updateCanDispatch()
      }

      // Network reachability
      let monitor = NWPathMonitor()
      monitor.pathUpdateHandler = { path in
         let reachable = path.status == .satisfied
         if isNetworkReachable != reachable {
            isNetworkReachable = reachable
            DispatchQueue.main.async {
               updateCanDispatch()
            }
         }
      }
      monitor.start(queue: pathMonitorQueue)
      pathMonitor = monitor

      // Initial evaluation and start timer
      updateCanDispatch()
      startDispatching()
   }

   private static func updateCanDispatch() {
      canDispatch = isAppActive && isNetworkReachable
   }

   private static func startDispatching() {
      guard dispatchTimer == nil else { return }

      DispatchQueue.main.async { // 메인 스레드 보장
         Logger.verbose("INAPP: Start dispatch timer (5s interval)")
         let timer = Timer(timeInterval: 5.0, repeats: true) { _ in
            handleInappEvent()
         }
         RunLoop.main.add(timer, forMode: commonMode)
         dispatchTimer = timer
         timer.fire()
      }
   }

   private static func handleInappEvent() {
      Logger.verbose("INAPP: Handling inapp event")

      // Ensure only when allowed
      if !canDispatch {
         Logger.verbose("INAPP: Not allowed to dispatch inapp event")
         return
      }

      let device = DeviceService.getBluxDeviceInfo()
      guard
         let deviceId = device.deviceId,
         let bluxId = device.bluxId,
         let clientId = SdkConfig.clientIdInUserDefaults
      else {
         Logger.verbose("INAPP: Not allowed to dispatch inapp event")
         return
      }

      if isDispatching { return }
      isDispatching = true

      let inappDispatchBody = InappDispatchRequest(bluxUserId: bluxId, deviceId: deviceId)

      Logger.verbose("INAPP: Dispatching inapp event")
      HTTPClient.shared.post(
         path: "/applications/" + clientId + "/inapps/dispatch",
         body: inappDispatchBody
      ) { (response: InappDispatchResponse?, error) in
         defer { isDispatching = false }
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
      _ baseViewController: UIViewController? = {
         if #available(iOS 13.0, *) {
            // iOS 13 이상에서는 connectedScenes를 사용
            guard let windowScene = UIApplication.shared.connectedScenes
               .compactMap({ $0 as? UIWindowScene })
               .first(where: { $0.activationState == .foregroundActive }),
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow })
            else {
               return nil
            }
            return keyWindow.rootViewController
         } else {
            // iOS 12 이하 호환용 (이 경우엔 keyWindow 사용 가능)
            return UIApplication.shared.keyWindow?.rootViewController
         }
      }()
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
