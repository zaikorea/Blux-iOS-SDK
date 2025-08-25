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
    static var sdkVersion = "0.5.1"
    static var sdkType: SdkType = .native
    
    static var bluxAppGroupNameKey = "BluxAppGroupName"
    static var bluxSuiteName = Bundle.main.object(forInfoDictionaryKey: bluxAppGroupNameKey) as? String
    
    static let bluxSdkInfoHeader: String = "X-BLUX-SDK-INFO"
    static let bluxClientIdHeader: String = "X-BLUX-CLIENT-ID"
    static let bluxAuthorizationHeader: String = "Authorization"
    static let bluxApiKeyHeader: String = "X-BLUX-API-KEY"
    static let bluxUnixTimestampHeader: String = "X-BLUX-TIMESTAMP"

    static var logLevel: LogLevel = .verbose
    static var requestPermissionOnLaunch: Bool = false
    
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
    
    private static var apiKey = "bluxAPIKey"
    static var apiKeyInUserDefaults: String? {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(newValue, forKey: apiKey)
        }
        
        get {
            UserDefaults(suiteName: bluxSuiteName)?.string(forKey: apiKey)
        }
    }
}
