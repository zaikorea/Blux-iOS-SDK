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
    static func create(completion: @escaping (() -> Void) = {}) {
        Logger.verbose("Start create device request.")
        
        let body = getBluxDeviceInfo()
        
        HTTPClient.shared.post(path: "/devices", body: body) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to request create device. - \(error)")
                return
            }
            
            if let bluxDeviceResponse = response {
                self.saveData(data: bluxDeviceResponse)
                Logger.verbose("Create device request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                Logger.verbose("Device ID: \(bluxDeviceResponse.deviceId).")
                completion()
            }
        }
    }
    
    /// Update device information to the latest
    static func activate(completion: @escaping (() -> Void) = {}) {
        guard SdkConfig.bluxIdInUserDefaults != nil else {
            return
        }
        guard SdkConfig.deviceIdInUserDefaults != nil else {
            return
        }
        
        Logger.verbose("Start activate device request.")
        
        let body = getBluxDeviceInfo()
        
        update(body: body) { (bluxDeviceResponse) in
            completion()
        }
    }
    
    /// Update device data such as key and value pair
    /// - Parameters:
    ///   - body: Data key & value
    static func update<T: Codable>(body: T, completion: ((BluxDeviceResponse)->())? = nil) {
        guard SdkConfig.bluxIdInUserDefaults != nil else {
            return
        }
        guard SdkConfig.deviceIdInUserDefaults != nil else {
            return
        }
        
        HTTPClient.shared.put(path: "/devices", body: body) { (response: BluxDeviceResponse?, error) in
            if let error = error  {
                Logger.error("Failed to request update device. - \(error)")
                return
            }
            
            if let bluxDeviceResponse = response {
                self.saveData(data: bluxDeviceResponse)
                Logger.verbose("Update device request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                Logger.verbose("User ID: \(bluxDeviceResponse.userId ?? "nil").")
                completion?(bluxDeviceResponse)
            }
            
        }
    }
    
    // static func updateUser<T: Codable>(body: T, completion: ((BluxDeviceResponse)->())? = nil) {}
    
    // Save data to the local storage.
    private static func saveData<T: Codable>(data: T) {
        if let bluxDeviceResponse = data as? BluxDeviceResponse {
            SdkConfig.bluxIdInUserDefaults = bluxDeviceResponse.bluxId
            SdkConfig.deviceIdInUserDefaults = bluxDeviceResponse.deviceId
            SdkConfig.userIdInUserDefaults = bluxDeviceResponse.userId
            SdkConfig.isSubscribedInUserDefaults = bluxDeviceResponse.isSubscribed
        }
    }
}
