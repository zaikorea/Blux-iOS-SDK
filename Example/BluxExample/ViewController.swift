//
//  ViewController.swift
//  Blux
//
//

import BluxClient
import UIKit
import WebKit

class ViewController: UIViewController {
    let userId = "team"

    // MARK: - UI (Programmatic)

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let eventTypeTextField = UITextField()
    private let keyTextField = UITextField()
    private let valueTextField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Storyboard로 올린 뷰가 있더라도, UI는 여기서 100% 코드로 다시 구성
        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = .systemBackground

        setupLayout()
        setupUI()

        // 키보드 숨기기 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fill

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            // stackView가 scrollView 폭에 맞게 늘어나도록
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])
    }

    private func setupUI() {
        // Setup
        addSectionTitle("Setup")
        stackView.addArrangedSubview(makeButton(title: "Initialize", action: #selector(initialize)))

        // User
        addSectionTitle("User")

        let authStack = UIStackView()
        authStack.axis = .horizontal
        authStack.spacing = 10
        authStack.distribution = .fillEqually
        authStack.addArrangedSubview(makeButton(title: "SignIn", action: #selector(signIn)))
        authStack.addArrangedSubview(makeButton(title: "SignOut", action: #selector(signOut)))
        stackView.addArrangedSubview(authStack)

        stackView.addArrangedSubview(makeButton(title: "Set User Properties", action: #selector(setUserProperties)))
        stackView.addArrangedSubview(makeButton(title: "Set Custom User Properties", action: #selector(setCustomUserProperties)))

        addSectionTitle("Events")

        // --- Custom Event Inputs (Events 섹션에 포함) ---
        eventTypeTextField.placeholder = "Event Type (required)"
        eventTypeTextField.text = "signup2"
        eventTypeTextField.borderStyle = .roundedRect
        stackView.addArrangedSubview(eventTypeTextField)

        let kvStack = UIStackView()
        kvStack.axis = .horizontal
        kvStack.spacing = 10
        kvStack.distribution = .fillEqually

        keyTextField.placeholder = "Prop Key"
        keyTextField.text = "test_key"
        keyTextField.borderStyle = .roundedRect

        valueTextField.placeholder = "Prop Value"
        valueTextField.text = "test_value"
        valueTextField.borderStyle = .roundedRect

        kvStack.addArrangedSubview(keyTextField)
        kvStack.addArrangedSubview(valueTextField)
        stackView.addArrangedSubview(kvStack)

        stackView.addArrangedSubview(makeButton(title: "Send Custom Event", action: #selector(sendCustomEvent)))

        stackView.addArrangedSubview(makeButton(title: "Send Like", action: #selector(sendLikeEvent)))
        stackView.addArrangedSubview(makeButton(title: "Send Cartadd", action: #selector(sendCartaddEvent)))
        stackView.addArrangedSubview(makeButton(title: "Send Order", action: #selector(sendOrderEvent)))

        // WebView
        addSectionTitle("WebView")
        stackView.addArrangedSubview(makeButton(title: "Open WebView", action: #selector(openWebView)))
    }

    private func addSectionTitle(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        stackView.addArrangedSubview(label)
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.tinted()
            config.title = title
            // storyboard 버튼 느낌에 가깝게: tinted 기본 + systemBlue
            config.baseForegroundColor = .systemBlue
            config.cornerStyle = .medium
            button.configuration = config
        } else {
            // iOS 15 미만에서도 'tinted' 느낌 유지
            button.setTitle(title, for: .normal)
            button.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            button.setTitleColor(.systemBlue, for: .normal)
            button.layer.cornerRadius = 10
        }

        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true // 기존 storyboard 버튼 높이(60)와 통일
        return button
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Actions

    @objc func initialize() {
        BluxClient.initialize(
            nil,
            bluxApplicationId: Credentials.getApplicationId(stage: StageHelper.getStage()),
            bluxAPIKey: Credentials.apiKey,
            requestPermissionOnLaunch: true
        ) { [weak self] error in
            DispatchQueue.main.async {
                let message = error == nil ? "Initialize 성공" : "Initialize 실패: \(error!.localizedDescription)"
                let alert = UIAlertController(title: "Blux", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    @objc func signIn() {
        BluxClient.signIn(userId: userId)
    }

    @objc func signOut() {
        BluxClient.signOut()
    }

    @objc func setUserProperties() {
        BluxClient.setUserProperties(userProperties: UserProperties(
            phoneNumber: "01012345678",
            emailAddress: "team@blux.ai",
            marketingNotificationConsent: true,
            marketingNotificationSmsConsent: true,
            marketingNotificationEmailConsent: true,
            marketingNotificationPushConsent: true,
            marketingNotificationKakaoConsent: true,
            nighttimeNotificationConsent: true,
            isAllNotificationBlocked: false,
            age: 100,
            gender: .female
        ))
    }

    @objc func setCustomUserProperties() {
        let customProperties: [String: Any] = [
            "is_active": true,
            "height": 5.9,
            "hobbies": ["reading", "gaming"],
        ]
        BluxClient.setCustomUserProperties(customUserProperties: customProperties)
    }

    @objc func sendCustomEvent() {
        guard let eventType = eventTypeTextField.text, !eventType.isEmpty else {
            print("Event Type is empty")
            return
        }

        do {
            var builder = AddCustomEvent.Builder(eventType: eventType)

            if let key = keyTextField.text, !key.isEmpty,
               let value = valueTextField.text, !value.isEmpty
            {
                builder = builder.customEventProperties([key: .string(value)])
            }

            let eventRequest = try builder.build()
            BluxClient.sendEvent(eventRequest)
            print("Custom Event Sent: \(eventType)")
        } catch {
            print(error.localizedDescription)
        }
    }

    @objc func sendLikeEvent() {
        do {
            let eventRequest = try AddLikeEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @objc func sendCartaddEvent() {
        do {
            let eventRequest = try AddCartaddEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @objc func sendOrderEvent() {
        do {
            let eventRequest = try AddOrderEvent.Builder()
                .orderId("order-example-\(Int(Date().timeIntervalSince1970))")
                .orderAmount(3000)
                .paidAmount(3000)
                .customEventProperties([
                    "source": .string("example_app"),
                    "channel": .string("ios"),
                    "order_count": .int(42),
                    "discount_rate": .double(0.15),
                    "is_test": .bool(true),
                ])
                .addItem(id: "item-1", price: 1000, quantity: 1, customEventProperties: [
                    "size": .string("L"),
                    "color": .string("navy"),
                    "weight_kg": .double(0.5),
                    "is_gift": .bool(false),
                ])
                .addItem(id: "item-2", price: 2000, quantity: 1, customEventProperties: [
                    "option": .string("premium"),
                    "stock": .int(100),
                    "on_sale": .bool(true),
                ])
                .addItem(id: "item-3", price: 0, quantity: 2)
                .build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @objc func openWebView() {
        guard let url = makeWebViewURL() else { return }
        let webViewVC = WebSdkBridgeViewController(url: url)
        let nav = UINavigationController(rootViewController: webViewVC)
        present(nav, animated: true)
    }

    private func makeWebViewURL() -> URL? {
        var components = URLComponents(string: "https://stg.sdk-demo.blux.ai")
        components?.queryItems = [
            URLQueryItem(name: "application_id", value: Credentials.getApplicationId(stage: StageHelper.getStage())),
            URLQueryItem(name: "api_key", value: Credentials.apiKey),
            URLQueryItem(name: "stage", value: StageHelper.getStage().rawValue),
            URLQueryItem(name: "platform", value: "ios"),
        ]
        return components?.url
    }
}

// MARK: - WebSdkBridgeViewController

class WebSdkBridgeViewController: UIViewController {
    private let url: URL
    private var webView: WKWebView!

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        title = "WebView"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )

        setupWebView()
        webView.load(URLRequest(url: url))
    }

    private func setupWebView() {
        webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        BluxWebSdkBridge.attach(to: webView)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    deinit {
        BluxWebSdkBridge.detach(from: webView)
    }
}
