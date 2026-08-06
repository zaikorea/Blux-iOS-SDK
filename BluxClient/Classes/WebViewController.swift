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
    private static let scriptHandlerName = "NativeiOSInterface"

    private var webView: WKWebView!
    private var content: Content
    private let messageHandler = WebViewMessageHandler()
    private var hasLoadedContent = false

    /// 내비게이션 바를 감출 때 웹 콘텐츠 위에 띄우는 닫기 버튼.
    /// fullScreen present라 이 버튼이 사라지면 화면을 빠져나갈 방법이 없어진다.
    private lazy var overlayCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 22
        button.accessibilityLabel = "Close"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(closeWebView), for: .touchUpInside)
        return button
    }()

    private var contentHost: String? {
        switch content {
        case let .url(url): return url.host
        case let .htmlString(_, baseURL): return baseURL.host
        }
    }

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
    required init?(coder _: NSCoder) {
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

        // 내비게이션 컨트롤러에 감싸인 웹 페이지는 바를 감추더라도 상태바를 침범하지 않는다.
        // 인앱 메시지는 컨트롤러 없이 전체 화면 오버레이로 띄우므로 view 최상단부터 그린다.
        let topAnchor = navigationController != nil
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
        // 로드 완료를 기다리면 바가 보였다 사라지므로 최초 host로 먼저 결정한다.
        applyChrome(for: contentHost)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateWebViewConstraints()
    }

    /// 순환 참조 2개를 끊는다.
    /// (1) userContentController가 self를 강하게 보유 (BannerWindow.dismiss와 동일 처리)
    /// (2) messageHandler의 클로저들이 self를 캡처
    /// 철거 후 재표시는 지원하지 않는다 — 호출부는 표시마다 VC를 새로 만든다.
    func teardownWebView() {
        webView.stopLoading()
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: Self.scriptHandlerName)
        messageHandler.removeAllHandlers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 다른 화면이 위에 덮인 경우가 아니라 "최종적으로 내려가는" 경우에만 철거한다.
        guard isBeingDismissed || isMovingFromParent
            || navigationController?.isBeingDismissed == true
        else { return }
        teardownWebView()
    }

    override func loadView() {
        super.loadView()

        let userContentController = WKUserContentController()
        userContentController.add(self, name: Self.scriptHandlerName)

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

        // 인앱 메시지는 호스트 앱 화면 위에 떠야 해서 배경이 비어야 하지만,
        // 웹 페이지는 바를 감췄을 때 상태바 영역이 뚫려 보이지 않도록 불투명하게 채운다.
        view.backgroundColor = navigationController != nil ? .white : .clear
        overrideUserInterfaceStyle = .light

        if #available(iOS 14.0, *) {
            navigationItem.leftBarButtonItem = .init(
                image: UIImage(systemName: "xmark"), style: .done, target: self,
                action: #selector(closeWebView)
            )
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
                action: #selector(closeWebView)
            )
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barTintColor = .lightGray
        }
        navigationController?.navigationBar.prefersLargeTitles = false

        view.addSubview(overlayCloseButton)
        NSLayoutConstraint.activate([
            // 랜딩 본문은 캠페인마다 다르지만 제목이 좌측에 오는 경우가 많아 우측에 둔다.
            overlayCloseButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            overlayCloseButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            overlayCloseButton.widthAnchor.constraint(equalToConstant: 44),
            overlayCloseButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    /// Blux 개인화 랜딩은 앱 자체 화면처럼 보이도록 내비게이션 바를 감추고 닫기 버튼만 남긴다.
    /// 그 외 host에서는 바와 host 표시를 되살려 어느 사이트를 보고 있는지 알 수 있게 한다.
    private func applyChrome(for host: String?) {
        let hidesBar = Self.shouldHideHost(host ?? "")
        navigationController?.setNavigationBarHidden(hidesBar, animated: false)
        overlayCloseButton.isHidden = !(hidesBar && navigationController != nil)
        navigationItem.title = hidesBar ? "" : host
        updateWebViewConstraints()
    }

    /// HTML 로드를 viewDidAppear까지 지연시켜, present 트랜지션이 끝난 뒤에만 webview가 메시지를
    /// 보내도록 한다. 배너용 인앱은 webview의 runtime이 즉시 `resize`를 발사하는데, 만약 이 메시지가
    /// `present` 트랜지션이 끝나기 전에 도착하면 `dismiss(animated: false)`가 무시되어 fullscreen
    /// WebViewController + BannerWindow가 동시에 보이는 race가 발생한다.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {
        switch content {
        case let .url(url):
            let request = URLRequest(url: url)
            webView.load(request)
        case let .htmlString(html, baseURL):
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    @objc
    private func closeWebView() {
        dismiss(animated: true, completion: nil)
    }

    func webView(
        _: WKWebView,
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
        if url.scheme != "http", url.scheme != "https" {
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

    // 유사 host 우회를 막기 위해 소문자 정규화 후 정확 일치로만 판정한다.
    static func shouldHideHost(_ host: String) -> Bool {
        ["landing.blux.ai", "dev.landing.blux.ai"].contains(host.lowercased())
    }

    // 이동이 시작되는 즉시 반영해, 외부 사이트를 여는 동안 host가 가려진 채로 남지 않게 한다.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        applyChrome(for: webView.url?.host)
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        applyChrome(for: webView.url?.host)
    }

    func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard
            message.name == Self.scriptHandlerName,
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
