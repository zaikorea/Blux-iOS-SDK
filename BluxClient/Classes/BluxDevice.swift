//
//  BluxDevice.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//

import Foundation

open class BluxDeviceResponse: Codable {
    public var bluxId: String
    public var deviceId: String
    public var userId: String?
    public var isSubscribed: Bool
    
    enum CodingKeys: String,
                     CodingKey {
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case isSubscribed = "is_subscribed"
    }
    
    public init(bluxId: String, deviceId: String, userId: String?, isSubscribed: Bool) {
        self.bluxId = bluxId
        self.deviceId = deviceId
        self.userId = userId
        self.isSubscribed = isSubscribed
    }
}

open class BluxDeviceInfo: Codable {
    // For update only
    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var pushToken: String?
    public var isSubscribed: Bool?
    
    // Create & Update
    public var platform: String
    public var deviceModel: String
    public var osVersion: String
    public var sdkVersion: String
    public var timezone: String
    public var languageCode: String?
    public var countryCode: String?
    public var sdkType: String
    public var lastActiveAt: String? = Utils.getISO8601DateString()
    
    enum CodingKeys: String,
                     CodingKey {
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case pushToken = "push_token"
        case isSubscribed = "is_subscribed"
        case platform = "platform"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case sdkVersion = "sdk_version"
        case timezone = "timezone"
        case languageCode = "language_code"
        case countryCode = "country_code"
        case sdkType = "sdk_type"
        case lastActiveAt = "last_active_at"
    }
    
    public init(
        pushToken: String? = nil,
        isSubscribed: Bool? = nil,
        platform: String,
        deviceModel: String,
        osVersion: String,
        sdkVersion: String,
        timezone: String,
        languageCode: String?,
        countryCode: String?,
        sdkType: String
    ) {
        self.pushToken = pushToken
        self.isSubscribed = isSubscribed
        self.platform = platform
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.sdkVersion = sdkVersion
        self.timezone = timezone
        self.languageCode = languageCode
        self.countryCode = countryCode
        self.sdkType = sdkType
    }
}

extension BluxDeviceInfo: CustomStringConvertible {
    public var description: String {
        var properties: [String] = []
        
        if let bluxId = bluxId {
            properties.append("bluxId: \(bluxId)")
        }
        if let deviceId = deviceId {
            properties.append("deviceId: \(deviceId)")
        }

        if let userId = userId {
            properties.append("userId: \(userId)")
        }
        if let pushToken = pushToken {
            properties.append("pushToken: \(pushToken)")
        }
        if let isSubscribed = isSubscribed {
            properties.append("isSubscribed: \(isSubscribed)")
        }
        
        properties.append("platform: \(platform)")
        properties.append("deviceModel: \(deviceModel)")
        properties.append("osVersion: \(osVersion)")
        properties.append("sdkVersion: \(sdkVersion)")
        properties.append("timezone: \(timezone)")
        
        if let languageCode = languageCode {
            properties.append("languageCode: \(languageCode)")
        }
        if let countryCode = countryCode {
            properties.append("countryCode: \(countryCode)")
        }
        
        properties.append("sdkType: \(sdkType)")
        
        if let lastActiveAt = lastActiveAt {
            properties.append("lastActiveAt: \(lastActiveAt)")
        }
        
        return "\n\t\(properties.joined(separator: "\n\t"))\n"
    }
}
