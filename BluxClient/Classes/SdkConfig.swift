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
    static var sdkVersion = "0.2.7"
    static var sdkType: SdkType = .native
    
    static let bluxSdkInfoHeader: String = "X-BLUX-SDK-INFO"
    static let bluxClientIdHeader: String = "X-BLUX-CLIENT-ID"
    static let bluxAuthorizationHeader: String = "Authorization"
    static let bluxApiKeyHeader: String = "X-BLUX-API-KEY"
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
            UserDefaults.standard.set(newValue, forKey: bluxIdKey)
        }
        
        get {
            UserDefaults.standard.string(forKey: bluxIdKey)
        }
    }
    
    /// Save deviceId in user defaults (local storage)
    private static var deviceIdKey = "bluxDeviceId"
    static var deviceIdInUserDefaults: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: deviceIdKey)
        }
        
        get {
            UserDefaults.standard.string(forKey: deviceIdKey)
        }
    }
    
    /// Save userId in user defaults (local storage)
    private static var userIdKey = "bluxUserId"
    static var userIdInUserDefaults: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: userIdKey)
        }
        
        get {
            UserDefaults.standard.string(forKey: userIdKey)
        }
    }
    
    /// Save clientId in user defaults (local storage)
    private static var clientIdKey = "bluxClientId"
    static var clientIdInUserDefaults: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: clientIdKey)
        }
        
        get {
            UserDefaults.standard.string(forKey: clientIdKey)
        }
    }
    
    private static var apiKey = "bluxAPIKey"
    static var apiKeyInUserDefaults: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: apiKey)
        }
        
        get {
            UserDefaults.standard.string(forKey: apiKey)
        }
    }
}
