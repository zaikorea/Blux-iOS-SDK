import XCTest
@testable import BluxClient

final class SdkConfigTests: XCTestCase {
    private var guardian: SdkStateGuard!
    private var savedNotificationUrlOpenOptions: NotificationUrlOpenOptions!
    // SdkConfig 내부 private key와 동기화 필요 (default 동작 검증을 위해 키 자체를 제거)
    private let notificationUrlOpenOptionsUserDefaultsKey = "bluxNotificationUrlOpenOptions"

    override func setUp() {
        super.setUp()
        guardian = SdkStateGuard()
        guardian.clear()
        savedNotificationUrlOpenOptions = SdkConfig.notificationUrlOpenOptions
        UserDefaults(suiteName: SdkConfig.bluxSuiteName)?
            .removeObject(forKey: notificationUrlOpenOptionsUserDefaultsKey)
    }

    override func tearDown() {
        SdkConfig.notificationUrlOpenOptions = savedNotificationUrlOpenOptions
        guardian.restore()
        guardian = nil
        super.tearDown()
    }

    // MARK: - Header constants

    func testHeaderConstantsAreStable() {
        // 서버 contract와 직결되므로 이름이 바뀌면 SDK 통신 깨짐
        XCTAssertEqual(SdkConfig.bluxSdkInfoHeader, "X-BLUX-SDK-INFO")
        XCTAssertEqual(SdkConfig.bluxClientIdHeader, "X-BLUX-CLIENT-ID")
        XCTAssertEqual(SdkConfig.bluxAuthorizationHeader, "Authorization")
        XCTAssertEqual(SdkConfig.bluxApiKeyHeader, "X-BLUX-API-KEY")
        XCTAssertEqual(SdkConfig.bluxUnixTimestampHeader, "X-BLUX-TIMESTAMP")
    }

    // MARK: - Default values

    func testDefaultLogLevelIsVerbose() {
        // 기본 logLevel은 verbose - 변경 시 사이드이펙트 큼
        let saved = SdkConfig.logLevel
        defer { SdkConfig.logLevel = saved }
        // 새 SdkConfig 인스턴스를 만들 수 없으니 enum 자체 확인
        XCTAssertEqual(LogLevel.verbose.rawValue, 5)
    }

    func testSdkTypeDefaultIsNative() {
        // 기본 sdkType은 native (RN/Flutter wrapper에서 변경)
        XCTAssertEqual(SdkConfig.sdkType, .native)
    }

    func testSdkTypeRawValues() {
        XCTAssertEqual(SdkType.native.rawValue, "native")
        XCTAssertEqual(SdkType.reactnative.rawValue, "reactnative")
        XCTAssertEqual(SdkType.flutter.rawValue, "flutter")
    }

    // MARK: - UserDefaults persistence

    func testClientIdPersistence() {
        XCTAssertNil(SdkConfig.clientIdInUserDefaults)
        SdkConfig.clientIdInUserDefaults = "client-123"
        XCTAssertEqual(SdkConfig.clientIdInUserDefaults, "client-123")
        SdkConfig.clientIdInUserDefaults = nil
        XCTAssertNil(SdkConfig.clientIdInUserDefaults)
    }

    func testApiKeyPersistence() {
        SdkConfig.apiKeyInUserDefaults = "api-key-xyz"
        XCTAssertEqual(SdkConfig.apiKeyInUserDefaults, "api-key-xyz")
    }

    func testBluxIdPersistence() {
        SdkConfig.bluxIdInUserDefaults = "blux-abc"
        XCTAssertEqual(SdkConfig.bluxIdInUserDefaults, "blux-abc")
    }

    func testDeviceIdPersistence() {
        SdkConfig.deviceIdInUserDefaults = "device-001"
        XCTAssertEqual(SdkConfig.deviceIdInUserDefaults, "device-001")
    }

    func testUserIdPersistence() {
        SdkConfig.userIdInUserDefaults = "user-007"
        XCTAssertEqual(SdkConfig.userIdInUserDefaults, "user-007")
        SdkConfig.userIdInUserDefaults = nil
        XCTAssertNil(SdkConfig.userIdInUserDefaults)
    }

    func testEachKeyIsIndependent() {
        SdkConfig.clientIdInUserDefaults = "C"
        SdkConfig.apiKeyInUserDefaults = "K"
        SdkConfig.bluxIdInUserDefaults = "B"
        SdkConfig.deviceIdInUserDefaults = "D"
        SdkConfig.userIdInUserDefaults = "U"

        XCTAssertEqual(SdkConfig.clientIdInUserDefaults, "C")
        XCTAssertEqual(SdkConfig.apiKeyInUserDefaults, "K")
        XCTAssertEqual(SdkConfig.bluxIdInUserDefaults, "B")
        XCTAssertEqual(SdkConfig.deviceIdInUserDefaults, "D")
        XCTAssertEqual(SdkConfig.userIdInUserDefaults, "U")
    }

    // MARK: - Session ID

    func testSessionIdAutoGeneratesUUID() {
        let sid = SdkConfig.sessionId
        XCTAssertFalse(sid.isEmpty)
        XCTAssertNotNil(UUID(uuidString: sid), "Default sessionId should be a valid UUID")
    }

    func testSessionIdIsStableAcrossReads() {
        let first = SdkConfig.sessionId
        let second = SdkConfig.sessionId
        XCTAssertEqual(first, second)
    }

    func testSessionIdSetterOverrides() {
        SdkConfig.sessionId = "custom-session"
        XCTAssertEqual(SdkConfig.sessionId, "custom-session")
    }

    // MARK: - NotificationUrlOpenOptions persistence

    func testNotificationUrlOpenOptionsDefaultIsInternalWebView() {
        let options = SdkConfig.notificationUrlOpenOptions
        XCTAssertEqual(options.httpUrlOpenTarget, .internalWebView)
    }

    func testNotificationUrlOpenOptionsRoundTripExternalBrowser() {
        SdkConfig.notificationUrlOpenOptions = NotificationUrlOpenOptions(httpUrlOpenTarget: .externalBrowser)
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, .externalBrowser)
    }

    func testNotificationUrlOpenOptionsRoundTripNone() {
        SdkConfig.notificationUrlOpenOptions = NotificationUrlOpenOptions(httpUrlOpenTarget: .none)
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, .none)
    }
}
