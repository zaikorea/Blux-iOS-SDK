//
//  DeviceService.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation

enum DeviceService {
    /// Get system information from device
    static func getBluxDeviceInfo() -> BluxDeviceInfo {
        // Select the preferred language to avoid errors when the device language and languageCode are different
        let languageCode =
            Locale.preferredLanguages.count > 0
                ? Locale(identifier: Locale.preferredLanguages.first!).languageCode
                : nil

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

    static func initializeDevice(
        deviceId: String?,
        completion: @escaping (Result<BluxDeviceResponse, Error>) -> Void = { _ in }
    ) {
        let body = getBluxDeviceInfo()
        body.deviceId = deviceId

        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            completion(.failure(NSError(domain: "DeviceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID not found"])))
            return
        }

        HTTPClient.shared.post(
            path: "/applications/" + clientId + "/blux-users/initialize",
            body: body
        ) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to request create device. - \(error)")
                completion(.failure(error))
                return
            }

            if let bluxDeviceResponse = response {
                SdkConfig.bluxIdInUserDefaults = bluxDeviceResponse.bluxId
                SdkConfig.deviceIdInUserDefaults = bluxDeviceResponse.deviceId
                SdkConfig.userIdInUserDefaults = nil

                Logger.verbose("Create device request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                Logger.verbose(
                    "Device ID: \(String(describing: bluxDeviceResponse.deviceId))."
                )
                completion(.success(bluxDeviceResponse))
            } else {
                completion(.failure(NSError(domain: "DeviceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])))
            }
        }
    }

    /// Update device data such as key and value pair
    /// - Parameters:
    ///   - body: Data key & value
    static func updatePushToken<T: Codable>(
        body: T,
        completion: @escaping (Result<BluxDeviceResponse, Error>) -> Void = { _ in }
    ) {
        guard let clientId = SdkConfig.clientIdInUserDefaults,
              let bluxId = SdkConfig.bluxIdInUserDefaults,
              let deviceId = SdkConfig.deviceIdInUserDefaults
        else {
            completion(.failure(NSError(domain: "DeviceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Required IDs not found"])))
            return
        }

        HTTPClient.shared.put(
            path: "/applications/" + clientId + "/blux-users/" + bluxId
                + "/devices/" + deviceId,
            body: body
        ) { (response: BluxDeviceResponse?, error) in
            if let error = error {
                Logger.error("Failed to update device. - \(error)")
                completion(.failure(error))
                return
            }

            if let bluxDeviceResponse = response {
                Logger.verbose("Update device request success.")
                Logger.verbose("Blux ID: \(bluxDeviceResponse.bluxId).")
                completion(.success(bluxDeviceResponse))
            } else {
                completion(.failure(NSError(domain: "DeviceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])))
            }
        }
    }
}
