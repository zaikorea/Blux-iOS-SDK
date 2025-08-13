//
//  BluxClient.swift
//  BluxClient
//
//  Copyright © 2024 Blux. All rights reserved.
//

// Used in setUserProperties, setCustomUserProperties
struct PropertiesWrapper<T: Codable>: Codable {
    var properties: T
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
        completion: @escaping ((NSError?) -> Void) = { _ in }
    ) {
        SdkConfig.requestPermissionOnLaunch = requestPermissionOnLaunch

        Logger.verbose("Initialize BluxClient with Application ID: \(bluxApplicationId).")
        SdkConfig.apiKeyInUserDefaults = bluxAPIKey

        // If saved clientId is nil or different, reset deviceId to nil
        let savedApplicationId = SdkConfig.clientIdInUserDefaults
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

        ColdStartNotificationManager.setColdStartNotification(
            launchOptions: launchOptions)

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

        DeviceService.initializeDevice(deviceId: savedDeviceId) { result in
            switch result {
            case .success:
                let eventRequest = EventRequest()
                eventRequest.events.append(Event(eventType: "visit"))
                self.sendEvent(eventRequest)
                // Enable in-app auto dispatch control after Blux user creation
                InappService.enableAutoDispatching()

                completion(nil)
                if requestPermissionOnLaunch {
                    requestPermissionForNotifications()
                }
            case .failure(let error):
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

    public static func setUserProperties(userProperties: UserProperties) {
        guard
            let clientId = SdkConfig.clientIdInUserDefaults,
            let bluxId = SdkConfig.bluxIdInUserDefaults
        else { return }

        // Input으로 받은 userProperties 객체를 한번 더 감싼 형태

        let propertiesWrapper = PropertiesWrapper(properties: userProperties)

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId
                + "/update-user-properties", body: propertiesWrapper
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

    // Used to convert customUserProperties to Codable
    enum CustomValue: Codable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case null
        case stringArray([String])

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Int.self) {
                self = .int(value)
            } else if let value = try? container.decode(Double.self) {
                self = .double(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
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

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .int(let value):
                try container.encode(value)
            case .double(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            case .stringArray(let value):
                try container.encode(value)
            case .null:
                try container.encodeNil()
            }
        }
    }

    public static func setCustomUserProperties(
        customUserProperties: [String: Any?]
    ) throws {
        guard
            let clientId = SdkConfig.clientIdInUserDefaults,
            let bluxId = SdkConfig.bluxIdInUserDefaults
        else { return }

        var processedCustomProperties: [String: CustomValue] = [:]

        for (key, value) in customUserProperties {
            if let stringValue = value as? String {
                processedCustomProperties[key] = .string(stringValue)
            } else if let intValue = value as? Int {
                processedCustomProperties[key] = .int(intValue)
            } else if let doubleValue = value as? Double {
                processedCustomProperties[key] = .double(doubleValue)
            } else if let boolValue = value as? Bool {
                processedCustomProperties[key] = .bool(boolValue)
            } else if let stringArrayValue = value as? [String] {
                processedCustomProperties[key] = .stringArray(stringArrayValue)
            } else {
                throw NSError(
                    domain: "", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unsupported type"]
                )
            }
        }

        let propertiesWrapper = PropertiesWrapper(
            properties: processedCustomProperties)

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId
                + "/update-custom-user-properties", body: propertiesWrapper
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

    public static func sendEventData(_ events: [Event]) {
        EventService.sendEvent(events)
    }

    /// Send Request
    public static func sendEvent(_ eventRequest: EventRequest) {
        sendEventData(eventRequest.getPayload())
    }

    /// Set the handler when notification is clicked
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

    /// Set the handler when notification foreground received
    @objc public static func setNotificationForegroundReceivedHandler(
        callback: @escaping (NotificationReceivedEvent) -> Void
    ) {
        EventHandlers.notificationForegroundReceived = callback
        Logger.verbose(
            "NotificationForegroundReceivedHandler has been registered.")
    }

    @objc public static func setAPIStage(_ stage: String) {
        let uppercasedStage = stage.uppercased()
        if uppercasedStage == "PROD" {
            HTTPClient.shared.setAPIStage(HTTPClient.APIBaseURLByStage.prod)
            return
        } else if uppercasedStage == "STG" {
            HTTPClient.shared.setAPIStage(HTTPClient.APIBaseURLByStage.stg)
            return
        } else if uppercasedStage == "DEV" {
            HTTPClient.shared.setAPIStage(HTTPClient.APIBaseURLByStage.dev)
            return
        } else if uppercasedStage == "LOCAL" {
            HTTPClient.shared.setAPIStage(HTTPClient.APIBaseURLByStage.local)
            return
        }

        Logger.verbose("Invalid stage string")
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
