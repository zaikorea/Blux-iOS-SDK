//
//  DeviceService.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation

final class DeviceService {
    /// Get system information from device
    static func getBluxDeviceInfo() -> BluxDeviceInfo {
        // Select the preferred language to avoid errors when the device language and languageCode are different
        let languageCode = Locale.preferredLanguages.count > 0 ? Locale(identifier: Locale.preferredLanguages.first!).languageCode : nil
        
        return BluxDeviceInfo(
            platform: "ios",
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            sdkVersion: SdkConfig.sdkVersion,
            timezone: TimeZone.current.identifier,
            languageCode: languageCode,
            countryCode: Locale.current.regionCode,
            sdkType: SdkConfig.sdkType.rawValue
        )
    }
    
    /// Create device data
    /// - Parameters:
    ///   - body: Data key & value
    
    static func initializeDevice(deviceId: String?, completion: @escaping (() -> Void) = {}) {
        let body = getBluxDeviceInfo()
        body.deviceId = deviceId
        
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }
        
        HTTPClient.shared.post(path: "/organizations/" + clientId + "/blux-users/initialize", body: body) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to request create device. - \(error)")
                return
            }
            
            if let bluxDeviceResponse = response {
                SdkConfig.bluxIdInUserDefaults = bluxDeviceResponse.bluxId
                SdkConfig.deviceIdInUserDefaults = bluxDeviceResponse.deviceId
                SdkConfig.userIdInUserDefaults = nil
                
                Logger.verbose("Create device request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                Logger.verbose("Device ID: \(String(describing: bluxDeviceResponse.deviceId)).")
                completion()
            }
        }
    }
    
    /// Update device data such as key and value pair
    /// - Parameters:
    ///   - body: Data key & value
    static func updatePushToken<T: Codable>(body: T, completion: ((BluxDeviceResponse)->())? = nil) {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }
        guard let bluxId = SdkConfig.bluxIdInUserDefaults else {
            return
        }
        guard let deviceId = SdkConfig.deviceIdInUserDefaults else {
            return
        }
        
        HTTPClient.shared.put(path: "/organizations/" + clientId + "/blux-users/" + bluxId + "/devices/" + deviceId, body: body) { (response: BluxDeviceResponse?, error) in
            if let error = error  {
                Logger.error("Failed to request update device. - \(error)")
                return
            }
            
            if let bluxDeviceResponse = response {
                Logger.verbose("Update device request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                completion?(bluxDeviceResponse)
            }
        }
    }
    
    // static func updateUser<T: Codable>(body: T, completion: ((BluxDeviceResponse)->())? = nil) {}
}
