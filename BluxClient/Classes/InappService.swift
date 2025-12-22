import Foundation
import Network
import UIKit
import WebKit

@available(iOSApplicationExtension, unavailable)
class InappService {
    private static var webViewQueue: [() -> Void] = []
    private static var isWebViewPresented = false

    private static var isAppActive: Bool = true
    private static var isNetworkReachable: Bool = true
    private static var lifecycleObserversRegistered: Bool = false
    
    private static var canDispatch: Bool {
        return isAppActive && isNetworkReachable
    }

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

    static func startMonitoringState() {
        if lifecycleObserversRegistered { return }
        lifecycleObserversRegistered = true

        NotificationCenter.default.addObserver(
            forName: didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = true
        }

        NotificationCenter.default.addObserver(
            forName: willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = false
        }

        NotificationCenter.default.addObserver(
            forName: didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = false
        }

        // Network reachability
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let reachable = path.status == .satisfied
            DispatchQueue.main.async {
                if isNetworkReachable != reachable {
                    isNetworkReachable = reachable
                }
            }
        }
        monitor.start(queue: pathMonitorQueue)
        pathMonitor = monitor
    }

    /// collect-events 응답에서 전달된 인앱 페이로드 처리
    /// inapp 객체가 있으면 표시 (shouldDisplay 필드 없이 객체 유무로 판단)
    static func handleInappResponse(_ response: InappDispatchResponse) {
        // 화면/네트워크 상태 체크
        guard canDispatch else {
            Logger.verbose("INAPP: Cannot display inapp (app inactive or offline)")
            return
        }

        Logger.verbose("INAPP: Dispatch response received. \(response.inappId) \(response.baseUrl)")
        guard let baseURL = URL(string: response.baseUrl) else {
            Logger.error("INAPP: Invalid baseUrl \(response.baseUrl)")
            return
        }
        queueInappWebview(response.notificationId, response.htmlString, response.inappId, baseURL)
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
                                createInappOpened(notificationId)
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

                createReceived(notificationId)
                Logger.verbose("INAPP: Presenting inapp webview.")
                webviewController.view.backgroundColor = .clear
                webviewController.modalPresentationStyle = .overFullScreen
                topController.present(
                    webviewController, animated: false, completion: nil
                )
            }
        }
    }

    private static func createInappOpened(_ notificationId: String) {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }

        let capturedAtString = ISO8601DateFormatter().string(from: Date())

        Logger.verbose("capturedAt: \(capturedAtString)")

        HTTPClient.shared.post(
            path: "/applications/" + clientId + "/crm-events",
            body: CRMEventsBody(
                notification_id: notificationId,
                crm_event_type: "inapp_opened",
                captured_at: capturedAtString
            )
        ) { (_: EmptyResponse?, error) in
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }
        }
    }

    private static func createReceived(_ notificationId: String) {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }

        struct StatusBody: Codable {
            let status: String
        }

        HTTPClient.shared.post(
            path: "/applications/" + clientId + "/notifications/"
                + notificationId, body: StatusBody(status: "received")
        ) { (response: BluxNotificationResponse?, error) in
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }

            if let notificationResponse = response {
                Logger.verbose("Create Received request success.")
                Logger.verbose(
                    "Notification ID: " + notificationResponse.id)
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
