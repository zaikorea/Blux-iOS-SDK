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

enum SdkConfig {
    /// 버전 SSoT. 배포 스크립트/워크플로우에서 빌드 시 실제 버전으로 변경됩니다. 이 값은 직접 수정하지 않습니다.
    /// - release-personal.sh: 로컬에서 임시 변경 (커밋 안 함)
    /// - release-internal.yml: 워크플로우에서 임시 변경 (커밋 안 함)
    /// - release-prod.yml: 워크플로우에서 release 브랜치에 커밋
    static var sdkVersion = "0.6.12"
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
    private static var notificationUrlOpenOptionsKey = "bluxNotificationUrlOpenOptions"
    static var notificationUrlOpenOptions: NotificationUrlOpenOptions {
        set {
            UserDefaults(suiteName: bluxSuiteName)?.set(
                newValue.httpUrlOpenTarget.rawValue,
                forKey: notificationUrlOpenOptionsKey
            )
        }
        get {
            guard let rawValue = UserDefaults(suiteName: bluxSuiteName)?
                .object(forKey: notificationUrlOpenOptionsKey) as? Int,
                let target = HttpUrlOpenTarget(rawValue: rawValue)
            else {
                return .init()
            }
            return NotificationUrlOpenOptions(httpUrlOpenTarget: target)
        }
    }

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

    /// Session ID for current app session (memory-based, not persisted)
    /// Automatically generates a UUID when first accessed
    private static var _sessionId: String?
    static var sessionId: String {
        get {
            if _sessionId == nil {
                _sessionId = UUID().uuidString
            }
            return _sessionId!
        }
        set {
            _sessionId = newValue
        }
    }
}
