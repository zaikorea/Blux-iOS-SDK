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
    @objc public static func initialize(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?, bluxClientId: String, bluxSecretKey: String, requestPermissionOnLaunch: Bool = true) {
        SdkConfig.requestPermissionOnLaunch = requestPermissionOnLaunch
        
        Logger.verbose("Initialize BluxClient with Client ID: \(bluxClientId).")
        SdkConfig.secretKeyInUserDefaults = bluxSecretKey
        
        // If saved clientId is nil or different, reset deviceId to nil
        let savedClientId = SdkConfig.clientIdInUserDefaults
        if savedClientId == nil || savedClientId != bluxClientId {
            SdkConfig.clientIdInUserDefaults = bluxClientId
            SdkConfig.deviceIdInUserDefaults = nil
            SdkConfig.isSubscribedInUserDefaults = nil
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
    @objc public static func setUserId(userId: String?) {
        guard SdkConfig.bluxIdInUserDefaults != nil else {
            return
        }
        guard SdkConfig.deviceIdInUserDefaults != nil else {
            return
        }
        
        let body = DeviceService.getBluxDeviceInfo()
        body.userId = userId
        
        DeviceService.update(body: body)
    }
    
    /// Send Request
    public static func sendRequest(_ request: EventRequest) {
        guard let deviceId = SdkConfig.deviceIdInUserDefaults else {
            return
        }
        guard let bluxId = SdkConfig.bluxIdInUserDefaults else {
            return
        }
        
        let requestData = request.getPayload()
        requestData.forEach { event in
            event.bluxId = bluxId
            event.deviceId = deviceId
            event.userId = SdkConfig.userIdInUserDefaults
        }
        
        EventService.sendRequest(requestData)
    }

    private static func deviceCreateOrActivate(_ requestPermissionOnLaunch: Bool) {
        if isActivated { return }
        isActivated = true
        
        if let savedDeviceId = SdkConfig.deviceIdInUserDefaults {
            Logger.verbose("Blux Device ID exists: \(savedDeviceId).")
            DeviceService.activate() {
                if requestPermissionOnLaunch {
                    requestPermissionForNotifications()
                }
            }
        } else {
            Logger.verbose("Blux Device ID does not exist, create new one.")
            DeviceService.create() {
                if requestPermissionOnLaunch {
                    requestPermissionForNotifications()
                }
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
    
    /// Request a permission and subscribe for notifications
    @objc public static func subscribe(fallbackToSettings: Bool = true, completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.requestPermissionForNotifications(completion: completion)
            } else if settings.authorizationStatus == .denied {
                if fallbackToSettings { // Open Notification Settings
                    DispatchQueue.main.async {
                        if #available(iOS 16.0, *) {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } else if #available(iOS 15.4, *) {
                            if let url = URL(string: UIApplicationOpenNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } else {
                            if let url = URL(string: "App-Prefs:root=NOTIFICATIONS_ID") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            } else {
                // Synchronize as much as possible to prevent cases where the token is absent in the DB
                self.requestPermissionForNotifications()
                self.setIsSubscribed(isSubscribed: true) { isSubscribed in
                    DispatchQueue.main.async {
                        completion?(isSubscribed)
                    }
                }
            }
        }
    }
    
    /// Unsubscribe for notifications
    @objc public static func unsubscribe(completion: ((Bool) -> Void)? = nil) {
        self.setIsSubscribed(isSubscribed: false) { isSubscribed in
            DispatchQueue.main.async {
                completion?(isSubscribed)
            }
        }
    }
    
    // MARK: Private Methods
    
    private static func requestPermissionForNotifications(completion: ((Bool) -> Void)? = nil) {
        let options: UNAuthorizationOptions = [.badge, .alert, .sound]
        
        // Execute completion if already authorized
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    completion?(true)
                } else {
                    completion?(false)
                }
            }
        }
    }
    
    /// Update isSubscribed of the device
    private static func setIsSubscribed(isSubscribed: Bool, completion: ((Bool) -> Void)? = nil) {
        guard SdkConfig.deviceIdInUserDefaults != nil else {
            return
        }
        
        let body = DeviceService.getBluxDeviceInfo()
        body.isSubscribed = isSubscribed
        
        if isSubscribed == true {
            body.pushToken = SdkConfig.pushTokenInUserDefaults
        }
        
        DeviceService.update(body: body) { bluxDevice in
            DispatchQueue.main.sync {
                completion?(bluxDevice.isSubscribed)
            }
        }
    }
}

