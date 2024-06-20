//
//  SdkConfig.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation

public enum SdkType: String {
    case native
    case reactnative
    case flutter
}

final class SdkConfig {
    static var sdkVersion = "0.2.0"
    static var sdkType: SdkType = .native
    static var bluxSuiteName = "group.ai.blux.app"
    
    static let hmacScheme: String = "Blux"
    static let bluxSdkInfoHeader: String = "X-BLUX-SDK-INFO"
    static let bluxClientIdHeader: String = "X-BLUX-CLIENT-ID"
    static let bluxAuthorizationHeader: String = "X-BLUX-AUTHORIZATION"
    static let bluxUnixTimestampHeader: String = "X-BLUX-TIMESTAMP"
    
    static let batchRequestCap: Int = 50
    static let epsilon: Double = 1e-4
    static let timeout: Double = 60
    
    static var logLevel: LogLevel = .verbose
    static var requestPermissionOnLaunch: Bool = false
    static var isSwizzled: Bool = false
    
    /// Save bluxId in user defaults (local storage)
    private static var bluxIdKey = "bluxId"
    static var bluxIdInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: bluxIdKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: bluxIdKey)
        }
    }
    
    /// Save deviceId in user defaults (local storage)
    private static var deviceIdKey = "bluxDeviceId"
    static var deviceIdInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: deviceIdKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: deviceIdKey)
        }
    }
    
    /// Save userId in user defaults (local storage)
    private static var userIdKey = "bluxUserId"
    static var userIdInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: userIdKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: userIdKey)
        }
    }
    
    /// Save clientId in user defaults (local storage)
    private static var clientIdKey = "bluxClientId"
    static var clientIdInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: clientIdKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: clientIdKey)
        }
    }
    
    private static var secretKey = "bluxSecretKey"
    static var secretKeyInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: secretKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: secretKey)
        }
    }
    
    /// Save APNs push token in user defaults (local storage)
    private static var pushTokenKey = "bluxPushTokenInUserDefaults"
    static var pushTokenInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: pushTokenKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: pushTokenKey)
        }
    }
    
    /// Save isSubscribed in user defaults (local storage)
    private static var isSubscribedKey = "bluxIsSubscribed"
    static var isSubscribedInUserDefaults: Bool? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: isSubscribedKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.bool(forKey: isSubscribedKey)
        }
    }
}
