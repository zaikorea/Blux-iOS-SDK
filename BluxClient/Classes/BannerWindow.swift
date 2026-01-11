//
//  BannerWindow.swift
//  BluxClient
//
//  Created by Blux on 2026/01/11.
//
import UIKit
@preconcurrency import WebKit

/// 배너 전용 Window - 배너 크기만큼만 화면을 차지하여 뒤쪽 터치가 가능
@available(iOSApplicationExtension, unavailable)
final class BannerWindow: UIWindow {
    
    private static let bannerMaxWidth: CGFloat = 448
    
    private var webView: WKWebView!
    private let messageHandler = WebViewMessageHandler()
    private var currentLocation: String = "top"
    
    init(htmlString: String, baseURL: URL) {
        // iOS 13+에서는 windowScene 필요
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) {
                super.init(windowScene: windowScene)
            } else {
                super.init(frame: .zero)
            }
        } else {
            super.init(frame: .zero)
        }
        
        setupWindow()
        setupWebView(htmlString: htmlString, baseURL: baseURL)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        backgroundColor = .clear
        windowLevel = .alert + 1  // 다른 윈도우 위에 표시
        isHidden = true  // 초기에는 숨김 (resize 메시지 후 표시)
        
        // 빈 root view controller 설정
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        rootViewController = vc
    }
    
    private func setupWebView(htmlString: String, baseURL: URL) {
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "NativeiOSInterface")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        
        if #available(iOS 14.0, *) {
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            webView.configuration.preferences.javaScriptEnabled = true
        }
        
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        rootViewController?.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        if let rootView = rootViewController?.view {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: rootView.topAnchor),
                webView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            ])
        }
        
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }
    
    /// 배너 크기와 위치 업데이트
    func updateLayout(height: CGFloat, location: String) {
        currentLocation = location
        
        let screenBounds = UIScreen.main.bounds
        let safeAreaInsets = getSafeAreaInsets()
        
        let bannerWidth = min(screenBounds.width * 0.9, BannerWindow.bannerMaxWidth)
        let bannerX = (screenBounds.width - bannerWidth) / 2
        
        let bannerY: CGFloat
        if location == "top" {
            bannerY = safeAreaInsets.top
        } else {
            bannerY = screenBounds.height - height - safeAreaInsets.bottom
        }
        
        let newFrame = CGRect(x: bannerX, y: bannerY, width: bannerWidth, height: height)
        
        if isHidden {
            // 처음 표시할 때
            frame = newFrame
            alpha = 0
            isHidden = false
            makeKeyAndVisible()
            
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1
            }
        } else {
            // 이미 표시 중이면 애니메이션으로 업데이트
            UIView.animate(withDuration: 0.2) {
                self.frame = newFrame
            }
        }
        
    }
    
    private func getSafeAreaInsets() -> UIEdgeInsets {
        if #available(iOS 13.0, *) {
            return windowScene?.windows.first?.safeAreaInsets ?? .zero
        } else {
            return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        }
    }
    
    /// 배너 닫기
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0
        }) { _ in
            self.webView.stopLoading()
            self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "NativeiOSInterface")
            self.isHidden = true
            self.resignKey()
            completion?()
        }
    }
    
    // MARK: - Message Handlers
    
    func addMessageHandler(for action: String, handler: @escaping (JSON) -> Void) {
        messageHandler.registerHandler(for: action, handler: handler)
    }
    
    func removeMessageHandler(for action: String) {
        messageHandler.unregisterHandler(for: action)
    }
}

// MARK: - WKNavigationDelegate
@available(iOSApplicationExtension, unavailable)
extension BannerWindow: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if url.absoluteString == "about:blank" {
            decisionHandler(.allow)
            return
        }
        
        if url.scheme != "http", url.scheme != "https" {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    Logger.verbose("BANNER: Failed to open URL: \(url)")
                }
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - WKScriptMessageHandler
@available(iOSApplicationExtension, unavailable)
extension BannerWindow: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard
            message.name == "NativeiOSInterface",
            let messageBody = message.body as? [String: Any]
        else { return }
        
        guard
            let action = messageBody["action"] as? String,
            let data = messageBody["data"] as? JSON
        else {
            Logger.verbose("BANNER: Invalid message format: \(messageBody)")
            return
        }
        
        // resize 액션은 내부에서 직접 처리
        if action == "resize" {
            if let height = data["height"] as? CGFloat,
               let location = data["location"] as? String {
                DispatchQueue.main.async {
                    self.updateLayout(height: height, location: location)
                }
            } else if let height = data["height"] as? Int,
                      let location = data["location"] as? String {
                DispatchQueue.main.async {
                    self.updateLayout(height: CGFloat(height), location: location)
                }
            }
            return
        }
        
        // 나머지 액션은 핸들러로 전달
        messageHandler.handleMessage(action, data: data)
    }
}
