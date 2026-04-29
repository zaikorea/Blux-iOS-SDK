//
//  BluxClient.swift
//  BluxClient
//
//  Copyright © 2024 Blux. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

// Used to convert userProperties and customUserProperties to Codable
enum CustomValue: Codable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case null
    case stringArray([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported type"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .stringArray(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

private extension CustomValue {
    static func fromAny(_ rawValue: Any?) -> CustomValue? {
        guard let rawValue else {
            return nil
        }

        if rawValue is NSNull {
            return .null
        }

        if let classifiedValue = NSNumberClassifier.classify(rawValue) {
            switch classifiedValue {
            case let .bool(value):
                return .bool(value)
            case let .int(value):
                return .int(value)
            case let .double(value):
                return .double(value)
            }
        }

        if let stringValue = rawValue as? String {
            return .string(stringValue)
        }

        if let stringArrayValue = rawValue as? [String] {
            return .stringArray(stringArrayValue)
        }

        return nil
    }
}

// Used in setUserProperties, setCustomUserProperties (bluxUsersUpdateProperties API)
struct UpdatePropertiesBody: Codable {
    var userProperties: [String: CustomValue]?
    var customUserProperties: [String: CustomValue]?

    enum CodingKeys: String, CodingKey {
        case userProperties = "user_properties"
        case customUserProperties = "custom_user_properties"
    }
}

@available(iOSApplicationExtension, unavailable)
@objc open class BluxClient: NSObject {
    private static var isActivated: Bool = false
    private static var appDelegate = BluxAppDelegate()

    /// Initialize Blux SDK
    @objc public static func initialize(
        _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        bluxApplicationId: String,
        bluxAPIKey: String,
        requestPermissionOnLaunch: Bool = true,
        customDeviceId: String? = nil,
        completion: @escaping ((NSError?) -> Void) = { _ in }
    ) {
        SdkConfig.requestPermissionOnLaunch = requestPermissionOnLaunch

        Logger.verbose("Initialize BluxClient with Application ID: \(bluxApplicationId).")

        // credentials가 변경된 경우 재초기화 허용 (stage 전환 후 재초기화 지원)
        // 쓰기 전에 저장된 값을 먼저 읽어야 API key만 교체되는 경우도 감지 가능.
        let savedApplicationId = SdkConfig.clientIdInUserDefaults
        let savedApiKey = SdkConfig.apiKeyInUserDefaults
        let credentialsChanged = (savedApplicationId != nil && savedApplicationId != bluxApplicationId)
            || (savedApiKey != nil && savedApiKey != bluxAPIKey)
        // 프로세스 내에서 initialize가 이미 호출된 상태에서 credential이 전환된 경우 식별 (isActivated 리셋 전 값 사용).
        // 프로세스 첫 initialize 호출 시에는 launchOptions가 정당한 데이터이므로 구분이 필요.
        let isInProcessCredentialSwitch = credentialsChanged && isActivated

        SdkConfig.apiKeyInUserDefaults = bluxAPIKey

        if credentialsChanged {
            isActivated = false
            ColdStartNotificationManager.reset()
            // 이전 credential 세션에서 대기 중이던 클릭이 새 credential로 재전달되지 않도록 초기화한다.
            EventHandlers.unhandledNotification = nil
            // 이전 세션에서 배칭된 이벤트가 새 세션의 bluxId로 전송되는 것을 막는다.
            EventService.clearPendingBatch()
            // 이전 세션에서 표시 중이던 인앱 메시지를 닫고 대기 큐도 비운다.
            InappService.dismissCurrentInApp()
            InappService.clearInappQueue()
            // 대기 중인 이벤트 태스크를 drop해 새 credential 아래에서 실행되지 않도록 한다.
            EventQueue.shared.clearPending()
        }

        // If saved clientId is nil or different, reset deviceId to nil
        if savedApplicationId == nil || savedApplicationId != bluxApplicationId {
            SdkConfig.clientIdInUserDefaults = bluxApplicationId
            SdkConfig.deviceIdInUserDefaults = nil
        }

        // Check UserDefaults availability
        guard SdkConfig.clientIdInUserDefaults == bluxApplicationId else {
            Logger.verbose("UserDefaults unavailable.")
            completion(NSError(domain: "BluxClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserDefaults unavailable."]))
            return
        }

        // 프로세스 내 credential 전환 시 전달된 launchOptions는 이전 credential의 푸시 페이로드일 수 있으므로 재처리하지 않는다.
        // (BluxNotification에는 credential 식별자가 없어 현재 credential 소속 여부를 판별할 수 없음.)
        ColdStartNotificationManager.setColdStartNotification(
            launchOptions: isInProcessCredentialSwitch ? nil : launchOptions)

        ColdStartNotificationManager.process()

        if isActivated {
            completion(nil)
            return
        }
        isActivated = true

        let savedDeviceId = SdkConfig.deviceIdInUserDefaults
        Logger.verbose(
            savedDeviceId != nil
                ? "Blux Device ID exists: \(savedDeviceId!)."
                : "Blux Device ID does not exist, create new one."
        )

        DeviceService.initializeDevice(deviceId: savedDeviceId, customDeviceId: customDeviceId) { result in
            switch result {
            case .success:
                // 초기화 완료 - 대기 중인 이벤트들 처리 시작
                EventQueue.shared.setInitialized()

                let eventRequest = EventRequest()
                eventRequest.events.append(Event(eventType: "visit"))
                self.sendEvent(eventRequest)
                // Enable in-app auto dispatch control after Blux user creation
                InappService.startMonitoringState()

                completion(nil)
                if requestPermissionOnLaunch {
                    requestPermissionForNotifications()
                }
            case let .failure(error):
                isActivated = false
                Logger.error("Failed to initialize device: \(error).")
                completion(error as NSError)
            }
        }
    }

    /// Set log level.
    @objc public static func setLogLevel(level: LogLevel) {
        Logger.verbose("Set log level to \(level).")
        SdkConfig.logLevel = level
    }

    @objc public static func setNotificationUrlOpenOptions(_ options: NotificationUrlOpenOptions) {
        SdkConfig.notificationUrlOpenOptions = options
    }

    @objc public static func setInAppUrlOpenOptions(_ options: InAppUrlOpenOptions) {
        SdkConfig.inAppUrlOpenOptions = options
    }

    /// Set userId of the device
    @objc public static func signIn(userId: String, completion: @escaping ((NSError?) -> Void) = { _ in }) {
        guard
            let clientId = SdkConfig.clientIdInUserDefaults,
            let bluxId = SdkConfig.bluxIdInUserDefaults,
            let deviceId = SdkConfig.deviceIdInUserDefaults
        else {
            completion(NSError(domain: "BluxClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Required IDs not found"]))
            return
        }

        let body = DeviceService.getBluxDeviceInfo()
        body.userId = userId
        body.deviceId = deviceId

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId
                + "/sign-in", body: body
        ) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to request sign-in. - \(error)")
                completion(NSError(domain: "BluxClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to request sign-in. - \(error)"]))
                return
            }

            if let bluxDeviceResponse = response {
                SdkConfig.bluxIdInUserDefaults = bluxDeviceResponse.bluxId
                SdkConfig.userIdInUserDefaults = userId
                Logger.verbose("Signin request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                completion(nil)
            }
        }
    }

    /// Signout from the device
    @objc public static func signOut() {
        // 이전 유저 세션에서 대기 중이던 클릭이 다음 유저로 재전달되지 않도록 초기화한다.
        EventHandlers.unhandledNotification = nil
        // 이전 유저의 배칭된 이벤트가 signOut 이후 재발급되는 bluxId로 전송되는 것을 막는다.
        EventService.clearPendingBatch()
        // 이전 유저에게 표시 중이던 인앱 메시지를 닫고 대기 큐도 비운다.
        InappService.dismissCurrentInApp()
        InappService.clearInappQueue()
        // 이전 유저의 대기 중인 이벤트 태스크를 drop해 새 anonymous identity로 실행되지 않도록 한다.
        EventQueue.shared.clearPending()

        guard
            let clientId = SdkConfig.clientIdInUserDefaults,
            let bluxId = SdkConfig.bluxIdInUserDefaults,
            let deviceId = SdkConfig.deviceIdInUserDefaults
        else { return }

        let body = DeviceService.getBluxDeviceInfo()
        body.deviceId = deviceId

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId
                + "/sign-out", body: body
        ) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to request sign-out. - \(error)")
                return
            }

            if let bluxDeviceResponse = response {
                SdkConfig.bluxIdInUserDefaults = bluxDeviceResponse.bluxId
                SdkConfig.userIdInUserDefaults = nil
                Logger.verbose("Signout request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
            }
        }
    }

    public static func setUserPropertiesData(userProperties: [String: Any?]) {
        guard
            let clientId = SdkConfig.clientIdInUserDefaults,
            let bluxId = SdkConfig.bluxIdInUserDefaults
        else { return }

        var processedProperties: [String: CustomValue] = [:]

        for (key, value) in userProperties {
            if let convertedValue = CustomValue.fromAny(value) {
                processedProperties[key] = convertedValue
            }
        }

        let body = UpdatePropertiesBody(userProperties: processedProperties)

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId + "/update-properties",
            body: body
        ) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }

            if let bluxDeviceResponse = response {
                Logger.verbose("SetUserProperties request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
            }
        }
    }

    public static func setUserProperties(userProperties: UserProperties) {
        // 기존 UserProperties 객체를 감싸던 부분 제거 → Dictionary 형태로 변환해서 넘김
        let userPropertiesDict: [String: Any?] = [
            "phone_number": userProperties.phoneNumber,
            "email_address": userProperties.emailAddress,
            "marketing_notification_consent": userProperties.marketingNotificationConsent,
            "marketing_notification_sms_consent": userProperties.marketingNotificationSmsConsent,
            "marketing_notification_email_consent": userProperties.marketingNotificationEmailConsent,
            "marketing_notification_push_consent": userProperties.marketingNotificationPushConsent,
            "marketing_notification_kakao_consent": userProperties.marketingNotificationKakaoConsent,
            "nighttime_notification_consent": userProperties.nighttimeNotificationConsent,
            "is_all_notification_blocked": userProperties.isAllNotificationBlocked,
            "age": userProperties.age,
            "gender": userProperties.gender?.rawValue,
        ]

        setUserPropertiesData(userProperties: userPropertiesDict)
    }

    public static func setCustomUserProperties(
        customUserProperties: [String: Any?]
    ) {
        guard
            let clientId = SdkConfig.clientIdInUserDefaults,
            let bluxId = SdkConfig.bluxIdInUserDefaults
        else { return }

        var processedCustomProperties: [String: CustomValue] = [:]

        for (key, value) in customUserProperties {
            if value == nil {
                processedCustomProperties[key] = .null
                continue
            }

            if let convertedValue = CustomValue.fromAny(value) {
                processedCustomProperties[key] = convertedValue
            } else {
                Logger.error("SetCustomUserProperties: unsupported type for key=\(key). This key is ignored.")
            }
        }

        let body = UpdatePropertiesBody(customUserProperties: processedCustomProperties)

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId + "/update-properties",
            body: body
        ) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }

            if let bluxDeviceResponse = response {
                Logger.verbose("SetCustomUserProperties request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
            }
        }
    }

    public static func sendRequestData(_ events: [Event]) {
        EventService.sendEvent(events)
    }

    /// Send Request
    public static func sendEvent(_ eventRequest: EventRequest) {
        sendRequestData(eventRequest.getPayload())
    }

    @objc public static func setNotificationForegroundWillDisplayHandler(
        callback: @escaping (NotificationReceivedEvent) -> Void
    ) {
        EventHandlers.notificationForegroundWillDisplay = callback
        Logger.verbose(
            "NotificationForegroundWillDisplayHandler has been registered.")
    }

    @objc public static func setNotificationClickedHandler(
        callback: @escaping (BluxNotification) -> Void
    ) {
        EventHandlers.notificationClicked = callback
        Logger.verbose("NotificationClickedHandler has been registered.")

        if let unhandledNotification = EventHandlers.unhandledNotification {
            Logger.verbose("Found unhandledNotification and execute handler.")
            callback(unhandledNotification)
            EventHandlers.unhandledNotification = nil
        }
    }

    /// Custom HTML 인앱 메시지에서 BluxBridge.triggerAction() 호출 시 실행될 핸들러를 등록합니다.
    /// 여러 핸들러를 등록할 수 있으며, 등록 순서대로 실행됩니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// let unsubscribe = BluxClient.addInAppCustomActionHandler { actionId, data in
    ///     if actionId == "share" {
    ///         // 공유 로직 구현
    ///     } else if actionId == "navigate" {
    ///         // 화면 이동 로직 구현
    ///     }
    /// }
    ///
    /// // 핸들러 제거
    /// unsubscribe()
    /// ```
    ///
    /// - Parameter callback: 액션 ID와 데이터를 받는 클로저
    /// - Returns: 핸들러를 제거하는 unsubscribe 함수
    public static func addInAppCustomActionHandler(
        callback: @escaping (_ actionId: String, _ data: [String: Any]) -> Void
    ) -> () -> Void {
        let id = UUID()
        EventHandlers.inAppCustomActionHandlers.append((id: id, handler: callback))
        Logger.verbose("InAppCustomActionHandler has been registered with id: \(id).")

        return {
            EventHandlers.inAppCustomActionHandlers.removeAll { $0.id == id }
            Logger.verbose("InAppCustomActionHandler has been removed with id: \(id).")
        }
    }

    /// 현재 표시 중인 인앱 메시지를 프로그래밍 방식으로 닫습니다.
    ///
    /// Custom HTML 인앱에서 async 핸들러 완료 후 수동으로 닫을 때 사용합니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// BluxClient.setInAppCustomActionHandler { actionId, data in
    ///     if actionId == "share" {
    ///         Task {
    ///             await shareContent(data)
    ///             BluxClient.dismissInApp() // async 작업 완료 후 수동으로 닫기
    ///         }
    ///     }
    /// }
    ///
    /// // HTML에서 shouldDismiss: false로 호출
    /// // BluxBridge.triggerAction('share', { url: '...' }, false);
    /// ```
    public static func dismissInApp() {
        InappService.dismissCurrentInApp()
    }

    static func hasPermissionForNotifications(
        completion: @escaping (Bool) -> Void
    ) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined
                || settings.authorizationStatus == .denied
            {
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    private static func requestPermissionForNotifications() {
        let options: UNAuthorizationOptions = [.badge, .alert, .sound]

        // 이미 사용자가 푸시 알림 권한을 부여한 상태라면, 권한 요청 팝업은 다시 나타나지 않습니다. 대신, requestAuthorization 메서드는 즉시 현재 권한 상태를 반환합니다.
        UNUserNotificationCenter.current().requestAuthorization(
            options: options
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    let body = DeviceService.getBluxDeviceInfo()
                    body.pushToken = nil

                    DeviceService.updatePushToken(body: body)
                }
            }
        }
    }
}
