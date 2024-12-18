//
//  WebViewController.swift
//  BluxClient
//
//  Created by Tommy on 6/4/24.
//
import UIKit
@preconcurrency import WebKit

@available(iOSApplicationExtension, unavailable)
final class WebViewController: UIViewController, WKNavigationDelegate,
    WKScriptMessageHandler
{
    private var webView: WKWebView!
    private var content: Content
    private let messageHandler = WebViewMessageHandler()

    // Content 타입 정의: URL 또는 HTML 문자열
    enum Content {
        case url(URL)
        case htmlString(html: String, baseURL: URL)
    }

    // 초기화 시 Content 선택
    init(content: Content) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateWebViewConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false

        // 기존 제약 조건 제거
        for constraint in view.constraints {
            if constraint.firstItem as? WKWebView == webView {
                view.removeConstraint(constraint)
            }
        }

        // Navigation Bar 유무에 따라 topAnchor 설정
        let topAnchor = navigationController?.isNavigationBarHidden == false
            ? view.safeAreaLayoutGuide.topAnchor
            : view.topAnchor

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWebViewConstraints()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateWebViewConstraints()
    }

    override func loadView() {
        super.loadView()

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

        // WebView 설정
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        view.addSubview(webView)

        // WebView를 슈퍼뷰 전체에 맞춤 (Safe Area 무시)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 뷰컨트롤러 배경 및 다크모드 영향 방지
        view.backgroundColor = .clear
        overrideUserInterfaceStyle = .light

        if #available(iOS 14.0, *) {
            navigationItem.leftBarButtonItem = .init(
                image: UIImage(systemName: "xmark"), style: .done, target: self,
                action: #selector(closeWebView))
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemGroupedBackground
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance =
                appearance
            navigationController?.navigationBar.compactAppearance = appearance
        } else {
            navigationItem.leftBarButtonItem = .init(
                barButtonSystemItem: .done, target: self,
                action: #selector(closeWebView))
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barTintColor = .lightGray
        }
        navigationController?.navigationBar.prefersLargeTitles = false

        // Content에 따라 로드
        loadContent()
    }

    private func loadContent() {
        switch content {
        case .url(let url):
            let request = URLRequest(url: url)
            webView.load(request)
        case .htmlString(let html, let baseURL):
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    @objc
    private func closeWebView() {
        dismiss(animated: true, completion: nil)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // about:blank 처리
        if url.absoluteString == "about:blank" {
            decisionHandler(.allow) // 웹뷰에서 렌더링 허용
            return
        }

        // http, https 외의 URL 스킴 처리
        if url.scheme != "http" && url.scheme != "https" {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Failed to open URL: \(url)")
                }
            }
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let host = webView.url?.host ?? ""
        navigationItem.title = host
    }

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
            Logger.verbose("Invalid message format: \(messageBody)")
            return
        }

        // 매니저로 메시지 전달
        messageHandler.handleMessage(action, data: data)
    }

    func addMessageHandler(
        for action: String, handler: @escaping (JSON) -> Void
    ) {
        messageHandler.registerHandler(for: action, handler: handler)
    }

    func removeMessageHandler(for action: String) {
        messageHandler.unregisterHandler(for: action)
    }
}
