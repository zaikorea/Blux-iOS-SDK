//
//  ViewController.swift
//  Blux
//
//

import BluxClient
import UIKit

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
        addSectionTitle("User")

        let authStack = UIStackView()
        authStack.axis = .horizontal
        authStack.spacing = 10
        authStack.distribution = .fillEqually
        authStack.addArrangedSubview(makeButton(title: "SignIn", action: #selector(SignIn)))
        authStack.addArrangedSubview(makeButton(title: "SignOut", action: #selector(SignOut)))
        stackView.addArrangedSubview(authStack)

        stackView.addArrangedSubview(makeButton(title: "Set User Properties", action: #selector(SetUserProperties)))
        stackView.addArrangedSubview(makeButton(title: "Set Custom User Properties", action: #selector(SetCustomUserProperties)))

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

        stackView.addArrangedSubview(makeButton(title: "Send Custom Event", action: #selector(sendCustomEventTapped)))

        stackView.addArrangedSubview(makeButton(title: "Send Like", action: #selector(SendLikeEvent)))
        stackView.addArrangedSubview(makeButton(title: "Send Cartadd", action: #selector(SendCartaddEvent)))
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

    @objc func sendCustomEventTapped() {
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

    @objc func SignIn() {
        BluxClient.signIn(userId: userId)
    }

    @objc func SignOut() {
        BluxClient.signOut()
    }

    @objc func SetUserProperties() {
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

    @objc func SetCustomUserProperties() {
        do {
            let customProperties: [String: Any] = [
                "is_active": true,
                "height": 5.9,
                "hobbies": ["reading", "gaming"],
            ]
            try BluxClient.setCustomUserProperties(customUserProperties: customProperties)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func SendLikeEvent(_: Any) {
        do {
            let eventRequest = try AddLikeEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @objc func SendCartaddEvent() {
        do {
            let eventRequest = try AddCartaddEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
