import XCTest
@testable import BluxClient

/// BluxDeviceInfo는 서버 initialize/sign-in/sign-out body 및 update push token body와 매칭.
/// 핵심: pushToken은 nil이어도 서버에 명시적으로 null로 전송돼야 함 (push token 제거 의도 표현).
/// userId도 nil이면 명시적 null (서버 기록).
final class BluxDeviceTests: XCTestCase {
    private var guardian: SdkStateGuard!
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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

    // MARK: - BluxDeviceResponse decoding

    func testBluxDeviceResponseDecodesSnakeCase() throws {
        let json = """
        { "blux_user_id": "B-1", "device_id": "D-1" }
        """.data(using: .utf8)!
        let response = try decoder.decode(BluxDeviceResponse.self, from: json)
        XCTAssertEqual(response.bluxId, "B-1")
        XCTAssertEqual(response.deviceId, "D-1")
    }

    func testBluxDeviceResponseDecodesWithoutDeviceId() throws {
        let json = "{ \"blux_user_id\": \"B-1\" }".data(using: .utf8)!
        let response = try decoder.decode(BluxDeviceResponse.self, from: json)
        XCTAssertEqual(response.bluxId, "B-1")
        XCTAssertNil(response.deviceId)
    }

    func testBluxDeviceResponseRequiresBluxUserId() {
        let json = "{ \"device_id\": \"D-1\" }".data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(BluxDeviceResponse.self, from: json))
    }

    // MARK: - BluxDeviceInfo encoding (snake_case keys & explicit null fields)

    func testEncodesAllRequiredFieldsWithSnakeCase() throws {
        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "iPhone17,1",
            osVersion: "18.0",
            sdkVersion: "1.2.3",
            timezone: "Asia/Seoul",
            languageCode: "ko",
            countryCode: "KR",
            sdkType: "native"
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["platform"] as? String, "ios")
        XCTAssertEqual(dict["device_model"] as? String, "iPhone17,1")
        XCTAssertEqual(dict["os_version"] as? String, "18.0")
        XCTAssertEqual(dict["sdk_version"] as? String, "1.2.3")
        XCTAssertEqual(dict["timezone"] as? String, "Asia/Seoul")
        XCTAssertEqual(dict["language_code"] as? String, "ko")
        XCTAssertEqual(dict["country_code"] as? String, "KR")
        XCTAssertEqual(dict["sdk_type"] as? String, "native")
    }

    func testEncodesPushTokenAsExplicitNullWhenNil() throws {
        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: nil,
            countryCode: nil,
            sdkType: "native"
        )
        info.pushToken = nil

        let data = try encoder.encode(info)
        // JSON에 push_token 키가 명시적으로 null로 존재해야 함 (서버 contract: null로 push token 제거)
        let raw = String(data: data, encoding: .utf8)!
        XCTAssertTrue(raw.contains("\"push_token\":null"),
                      "push_token must be explicitly null. Got: \(raw)")
    }

    func testEncodesPushTokenWhenSet() throws {
        let info = BluxDeviceInfo(
            pushToken: "abc123",
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: nil,
            countryCode: nil,
            sdkType: "native"
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["push_token"] as? String, "abc123")
    }

    func testEncodesUserIdAsExplicitNullWhenNil() throws {
        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: nil,
            countryCode: nil,
            sdkType: "native"
        )
        // userId는 SdkConfig.userIdInUserDefaults를 따라가는데 setUp에서 비웠으니 nil
        XCTAssertNil(info.userId)

        let data = try encoder.encode(info)
        let raw = String(data: data, encoding: .utf8)!
        XCTAssertTrue(raw.contains("\"user_id\":null"),
                      "user_id must be explicitly null when not signed in. Got: \(raw)")
    }

    func testEncodesUserIdWhenSdkConfigSet() throws {
        SdkConfig.userIdInUserDefaults = "user-9"

        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: nil,
            countryCode: nil,
            sdkType: "native"
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["user_id"] as? String, "user-9")
    }

    func testEncodingExplicitlyNullsBluxIdButOmitsDeviceIdWhenNil() throws {
        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: nil,
            countryCode: nil,
            sdkType: "native"
        )
        let data = try encoder.encode(info)
        let raw = String(data: data, encoding: .utf8)!

        // bluxId는 try container.encode(bluxId, forKey:) 직접 호출 → nil이면 명시적 null로 인코딩됨
        XCTAssertTrue(raw.contains("\"blux_id\":null"),
                      "blux_id should be explicit null. Got: \(raw)")
        // deviceId는 if-let 가드 후 encode → nil이면 키 자체가 빠짐
        XCTAssertFalse(raw.contains("device_id"),
                       "device_id key should be absent when nil. Got: \(raw)")
    }

    func testEncodesOptionalFieldsWhenPresent() throws {
        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: "ko",
            countryCode: "KR",
            sdkType: "native",
            sessionId: "S-1",
            appVersion: "9.9.9"
        )
        info.customDeviceId = "CD"

        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["session_id"] as? String, "S-1")
        XCTAssertEqual(dict["app_version"] as? String, "9.9.9")
        XCTAssertEqual(dict["custom_device_id"] as? String, "CD")
    }

    func testInheritsSessionIdFromSdkConfigWhenInitNotProvided() {
        SdkConfig.sessionId = "auto-S"
        let info = BluxDeviceInfo(
            platform: "ios",
            deviceModel: "X",
            osVersion: "0",
            sdkVersion: "0",
            timezone: "UTC",
            languageCode: nil,
            countryCode: nil,
            sdkType: "native"
        )
        XCTAssertEqual(info.sessionId, "auto-S")
    }

    // MARK: - description

    func testDescriptionContainsPresentFields() {
        SdkConfig.bluxIdInUserDefaults = "B"
        SdkConfig.deviceIdInUserDefaults = "D"
        SdkConfig.userIdInUserDefaults = "U"

        let info = BluxDeviceInfo(
            pushToken: "T",
            platform: "ios",
            deviceModel: "X",
            osVersion: "1.0",
            sdkVersion: "0.0.1",
            timezone: "Asia/Seoul",
            languageCode: "ko",
            countryCode: "KR",
            sdkType: "native",
            appVersion: "1.0"
        )

        let desc = info.description
        XCTAssertTrue(desc.contains("bluxId: B"))
        XCTAssertTrue(desc.contains("deviceId: D"))
        XCTAssertTrue(desc.contains("userId: U"))
        XCTAssertTrue(desc.contains("pushToken: T"))
        XCTAssertTrue(desc.contains("platform: ios"))
        XCTAssertTrue(desc.contains("countryCode: KR"))
    }
}
