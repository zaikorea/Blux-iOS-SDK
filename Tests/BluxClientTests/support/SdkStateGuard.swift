import Foundation
@testable import BluxClient

/// SdkConfig + EventHandlers + ColdStartNotificationManager의 정적 상태를 테스트마다 격리한다.
/// SDK 전반의 정적 슬롯을 한 곳에서 관리해 setUp/tearDown 누락으로 인한 테스트 간 누수를 방지.
///
/// 사용:
///   override func setUp() { super.setUp(); guardian = SdkStateGuard(); guardian.clear() }
///   override func tearDown() { guardian.restore(); super.tearDown() }
final class SdkStateGuard {
    private var savedClientId: String?
    private var savedApiKey: String?
    private var savedBluxId: String?
    private var savedDeviceId: String?
    private var savedUserId: String?
    private var savedLogLevel: LogLevel
    private var savedSessionId: String
    private var savedRequestPermissionOnLaunch: Bool

    init() {
        savedClientId = SdkConfig.clientIdInUserDefaults
        savedApiKey = SdkConfig.apiKeyInUserDefaults
        savedBluxId = SdkConfig.bluxIdInUserDefaults
        savedDeviceId = SdkConfig.deviceIdInUserDefaults
        savedUserId = SdkConfig.userIdInUserDefaults
        savedLogLevel = SdkConfig.logLevel
        savedSessionId = SdkConfig.sessionId
        savedRequestPermissionOnLaunch = SdkConfig.requestPermissionOnLaunch
    }

    func clear() {
        SdkConfig.clientIdInUserDefaults = nil
        SdkConfig.apiKeyInUserDefaults = nil
        SdkConfig.bluxIdInUserDefaults = nil
        SdkConfig.deviceIdInUserDefaults = nil
        SdkConfig.userIdInUserDefaults = nil

        EventHandlers.unhandledNotification = nil
        EventHandlers.notificationClicked = nil
        EventHandlers.notificationForegroundWillDisplay = nil
        EventHandlers.inAppClicked = nil
        EventHandlers.inAppCustomActionHandlers = []

        ColdStartNotificationManager.coldStartNotification = nil
        ColdStartNotificationManager.reset()

        UserDefaults(suiteName: SdkConfig.bluxSuiteName)?.removeObject(forKey: Stage.overrideStageKey)
    }

    func restore() {
        SdkConfig.clientIdInUserDefaults = savedClientId
        SdkConfig.apiKeyInUserDefaults = savedApiKey
        SdkConfig.bluxIdInUserDefaults = savedBluxId
        SdkConfig.deviceIdInUserDefaults = savedDeviceId
        SdkConfig.userIdInUserDefaults = savedUserId
        SdkConfig.logLevel = savedLogLevel
        SdkConfig.sessionId = savedSessionId
        SdkConfig.requestPermissionOnLaunch = savedRequestPermissionOnLaunch

        EventHandlers.unhandledNotification = nil
        EventHandlers.notificationClicked = nil
        EventHandlers.notificationForegroundWillDisplay = nil
        EventHandlers.inAppClicked = nil
        EventHandlers.inAppCustomActionHandlers = []

        ColdStartNotificationManager.coldStartNotification = nil
        ColdStartNotificationManager.reset()

        UserDefaults(suiteName: SdkConfig.bluxSuiteName)?.removeObject(forKey: Stage.overrideStageKey)
    }
}
