
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
    
    /// Initialize Blux SDK
    /// - Parameters:
    ///   - launchOptions: AppDelegate didFinishLaunchingWithOptions
    @objc public static func initialize(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?, bluxClientId: String, bluxSecretKey: String) {
        
        Logger.verbose("Initialize BluxClient with ClientID: \(bluxClientId).")
        SdkConfig.bluxSecretKey = bluxSecretKey
        
        // If clientId is nil or different, reset device id to nil
        let savedClientId = SdkConfig.clientIdInUserDefaults
        if savedClientId == nil || savedClientId != bluxClientId {
            SdkConfig.clientIdInUserDefaults = bluxClientId
            SdkConfig.deviceIdInUserDefaults = nil
        }
        
        deviceRegisterOrActivate()
    }
    
    // MARK: - Public Methods
    
    /// Set level to logging
    /// - Parameter level: LogLevel, Default is verbose
    @objc public static func setLogLevel(level: LogLevel) {
        Logger.verbose("Set log level to \(level).")
        SdkConfig.logLevel = level
    }
    
    /// Set SDK info
    /// - Parameters:
    ///   - sdkType: Platform in which the SDK runs
    ///   - sdkVersion: Version of SDK by Platform
    /// Must called before initialize
    public static func setSdkInfo(sdkType: SdkType, sdkVersion: String) {
        Logger.verbose("Set SDK info as \(sdkType), \(sdkVersion).")
        SdkConfig.sdkType = sdkType
        SdkConfig.sdkVersion = sdkVersion
    }
    
    /// Set userId of device
    /// - Parameter userId: userId
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
    /// - Parameters:
    ///   - request: event data
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
    
    public static func deviceRegisterOrActivate() {
        if isActivated { return }
        isActivated = true
        
        // 저장되어 있는 deviceId 가져오기
        if let savedDeviceId = SdkConfig.deviceIdInUserDefaults {
            Logger.verbose("savedDeviceId exists: \(savedDeviceId).")
            DeviceService.activate()
        } else {
            Logger.verbose("savedDeviceId does not exist, newly register.")
            DeviceService.register()
        }
    }
}
