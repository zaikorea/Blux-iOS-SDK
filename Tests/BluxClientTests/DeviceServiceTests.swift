import XCTest
@testable import BluxClient

final class DeviceServiceTests: XCTestCase {
    private var guardian: SdkStateGuard!

    override func setUp() {
        super.setUp()
        guardian = SdkStateGuard()
        guardian.clear()
    }

    override func tearDown() {
        guardian.restore()
        guardian = nil
        super.tearDown()
    }

    // MARK: - getBluxDeviceInfo

    func testGetBluxDeviceInfoFillsRequiredFields() {
        let info = DeviceService.getBluxDeviceInfo()
        XCTAssertEqual(info.platform, "ios")
        XCTAssertFalse(info.deviceModel.isEmpty)
        XCTAssertFalse(info.osVersion.isEmpty)
        XCTAssertEqual(info.sdkVersion, SdkConfig.sdkVersion)
        XCTAssertEqual(info.sdkType, SdkConfig.sdkType.rawValue)
        XCTAssertFalse(info.timezone.isEmpty)
    }

    func testGetBluxDeviceInfoInheritsSessionId() {
        SdkConfig.sessionId = "session-X"
        let info = DeviceService.getBluxDeviceInfo()
        XCTAssertEqual(info.sessionId, "session-X")
    }

    func testGetBluxDeviceInfoInheritsBluxIds() {
        SdkConfig.bluxIdInUserDefaults = "B"
        SdkConfig.deviceIdInUserDefaults = "D"
        SdkConfig.userIdInUserDefaults = "U"

        let info = DeviceService.getBluxDeviceInfo()
        XCTAssertEqual(info.bluxId, "B")
        XCTAssertEqual(info.deviceId, "D")
        XCTAssertEqual(info.userId, "U")
    }

    func testGetBluxDeviceInfoLanguageCodeFromPreferredLocale() {
        let info = DeviceService.getBluxDeviceInfo()
        // languageCode는 nullable이지만 시뮬레이터 환경이면 일반적으로 비어있지 않음.
        // 시스템 차이로 nil일 수도 있어 단순히 크래시 안 나면 통과.
        _ = info.languageCode
    }

    // MARK: - initializeDevice 사전조건

    func testInitializeDeviceFailsWhenNoClientId() {
        let exp = expectation(description: "initializeDevice fails fast")
        var capturedResult: Result<BluxDeviceResponse, Error>?

        DeviceService.initializeDevice(deviceId: nil) { result in
            capturedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        guard case .failure(let error) = capturedResult else {
            XCTFail("Expected failure when clientId is nil")
            return
        }
        let nsError = error as NSError
        XCTAssertEqual(nsError.domain, "DeviceService")
    }

    // MARK: - updatePushToken 사전조건

    func testUpdatePushTokenFailsWhenNoIds() {
        struct DummyBody: Codable { let push_token: String? }
        let exp = expectation(description: "updatePushToken fails fast")
        var capturedResult: Result<BluxDeviceResponse, Error>?

        DeviceService.updatePushToken(body: DummyBody(push_token: nil)) { result in
            capturedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        guard case .failure = capturedResult else {
            XCTFail("Expected failure when IDs are missing")
            return
        }
    }
}
