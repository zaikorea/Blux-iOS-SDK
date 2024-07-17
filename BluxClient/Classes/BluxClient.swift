//
//  BluxClient.swift
//  BluxClient
//
//  Copyright © 2024 Blux. All rights reserved.
//

import UIKit

@available(iOSApplicationExtension, unavailable)
@objc open class BluxClient: NSObject {
    private static var isActivated: Bool = false
    static private var appDelegate = BluxAppDelegate()
    static private let swizzlingEnabledKey = "BluxSwizzlingEnabled"
    
    // MARK: - Public Methods
    
    /// Initialize Blux SDK
    @objc public static func initialize(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?, bluxClientId: String, bluxAPIKey: String, requestPermissionOnLaunch: Bool = true) {
        SdkConfig.requestPermissionOnLaunch = requestPermissionOnLaunch
        
        Logger.verbose("Initialize BluxClient with Client ID: \(bluxClientId).")
        SdkConfig.apiKeyInUserDefaults = bluxAPIKey
        
        // If saved clientId is nil or different, reset deviceId to nil
        let savedClientId = SdkConfig.clientIdInUserDefaults
        if savedClientId == nil || savedClientId != bluxClientId {
            SdkConfig.clientIdInUserDefaults = bluxClientId
            SdkConfig.deviceIdInUserDefaults = nil
        }
        
        // Check UserDefaults availability
        guard SdkConfig.clientIdInUserDefaults == bluxClientId else {
            Logger.verbose("UserDefaults unavailable.")
            return
        }
        
        ColdStartNotificationManager.setColdStartNotification(launchOptions: launchOptions)
        
        let swizzlingEnabled = Bundle.main.object(forInfoDictionaryKey: swizzlingEnabledKey) as? Bool
        if swizzlingEnabled != false {
            UNUserNotificationCenter.current().delegate = BluxNotificationCenter.shared
            appDelegate.swizzle()
        }
        
        ColdStartNotificationManager.process()
        
        deviceCreateOrActivate(requestPermissionOnLaunch)
    }
    
    /// Set log level.
    @objc public static func setLogLevel(level: LogLevel) {
        Logger.verbose("Set log level to \(level).")
        SdkConfig.logLevel = level
    }
    
    /// Set userId of the device
    @objc public static func signIn(userId: String) {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }
        guard let bluxId = SdkConfig.bluxIdInUserDefaults else {
            return
        }
        
        let body = DeviceService.getBluxDeviceInfo()
        body.userId = userId
        
        HTTPClient.shared.put(path: "/organizations/" + clientId + "/blux-users/" + bluxId + "/sign-in", body: body, apiType: "IDENTIFIER") { (response: BluxDeviceResponse?, error) in
            if let error = error  {
                Logger.error("Failed to request sign-in. - \(error)")
                return
            }
            
            if let bluxDeviceResponse = response {
                SdkConfig.bluxIdInUserDefaults = bluxDeviceResponse.bluxId
                SdkConfig.userIdInUserDefaults = userId
                Logger.verbose("Signin request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
            }
        }
    }
    
    /// Signout from the device
    @objc public static func signOut() {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }
        guard let bluxId = SdkConfig.bluxIdInUserDefaults else {
            return
        }
        guard let deviceId = SdkConfig.deviceIdInUserDefaults else {
            return
        }
        
        let body = DeviceService.getBluxDeviceInfo()
        body.deviceId = deviceId
        
        HTTPClient.shared.put(path: "/organizations/" + clientId + "/blux-users/" + bluxId + "/sign-out", body: body, apiType: "IDENTIFIER") { (response: BluxDeviceResponse?, error) in
            if let error = error  {
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


    public static func sendRequestData(_ data: [Event]) {
        guard let deviceId = SdkConfig.deviceIdInUserDefaults else {
            return
        }
        guard let bluxId = SdkConfig.bluxIdInUserDefaults else {
            return
        }
        
        data.forEach { event in
            event.bluxId = bluxId
            event.deviceId = deviceId
            event.userId = SdkConfig.userIdInUserDefaults
        }
        
        EventService.sendRequest(data)
    }
    
    /// Send Request
    public static func sendRequest(_ request: EventRequest) {
        let requestData = request.getPayload()
        self.sendRequestData(requestData)
    }

    private static func deviceCreateOrActivate(_ requestPermissionOnLaunch: Bool) {
        if isActivated { return }
        isActivated = true
        
        let savedDeviceId = SdkConfig.deviceIdInUserDefaults

        Logger.verbose(savedDeviceId != nil ? "Blux Device ID exists: \(savedDeviceId!)." : "Blux Device ID does not exist, create new one.")

        DeviceService.initializeDevice(deviceId: savedDeviceId) {
            if requestPermissionOnLaunch {
                requestPermissionForNotifications()
            }
        }
    }
    
    /// Set the handler when notification is clicked
    @objc public static func setNotificationClickedHandler(callback: @escaping (BluxNotification) -> Void) {
        EventHandlers.notificationClicked = callback
        Logger.verbose("NotificationClickedHandler has been registered.")
        
        if let unhandledNotification = EventHandlers.unhandledNotification {
            Logger.verbose("Found unhandledNotification and execute handler.")
            callback(unhandledNotification)
            EventHandlers.unhandledNotification = nil
        }
    }
    
    /// Set the handler when notification foreground received
    @objc public static func setNotificationForegroundReceivedHandler(callback: @escaping (NotificationReceivedEvent) -> Void) {
        EventHandlers.notificationForegroundReceived = callback
        Logger.verbose("NotificationForegroundReceivedHandler has been registered.")
    }
    
    static func hasPermissionForNotifications(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .denied {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: Private Methods
    
    private static func requestPermissionForNotifications() {
        let options: UNAuthorizationOptions = [.badge, .alert, .sound]
        
        // 이미 사용자가 푸시 알림 권한을 부여한 상태라면, 권한 요청 팝업은 다시 나타나지 않습니다. 대신, requestAuthorization 메서드는 즉시 현재 권한 상태를 반환합니다.
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
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

