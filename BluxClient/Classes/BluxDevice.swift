//
//  BluxDevice.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//

import Foundation

open class BluxDeviceResponse: Codable {
    public var bluxId: String
    public var deviceId: String?
    
    enum CodingKeys: String,
                     CodingKey {
        case bluxId = "blux_user_id"
        case deviceId = "device_id"
    }
    
    public init(bluxId: String, deviceId: String?) {
        self.bluxId = bluxId
        self.deviceId = deviceId
    }
}

open class BluxDeviceInfo: Codable {
    // For update only
    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var pushToken: String?
    
    // Create & Update
    public var platform: String
    public var deviceModel: String
    public var osVersion: String
    public var sdkVersion: String
    public var timezone: String
    public var languageCode: String?
    public var countryCode: String?
    public var sdkType: String
    public var isVisitHandlingInSdk: Bool = true
    
    
    enum CodingKeys: String,
                     CodingKey {
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case pushToken = "push_token"
        case platform = "platform"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case sdkVersion = "sdk_version"
        case timezone = "timezone"
        case languageCode = "language_code"
        case countryCode = "country_code"
        case sdkType = "sdk_type"
        case isVisitHandlingInSdk = "isVisitHandlingInSdk"
    }
    
    public init(
        pushToken: String? = nil,
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
        self.platform = platform
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.sdkVersion = sdkVersion
        self.timezone = timezone
        self.languageCode = languageCode
        self.countryCode = countryCode
        self.sdkType = sdkType
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bluxId, forKey: .bluxId)
        if let deviceId = deviceId {
            try container.encode(deviceId, forKey: .deviceId)
        }
        
        if let userId = userId {
            try container.encode(userId, forKey: .userId)
        }
        else {
            try container.encodeNil(forKey: .userId) // "null" on server
        }

        try container.encode(pushToken, forKey: .pushToken)

        try container.encode(platform, forKey: .platform)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(languageCode, forKey: .languageCode)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(sdkType, forKey: .sdkType)
        try container.encode(isVisitHandlingInSdk, forKey: .isVisitHandlingInSdk)
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
        
        return "\n\t\(properties.joined(separator: "\n\t"))\n"
    }
}
