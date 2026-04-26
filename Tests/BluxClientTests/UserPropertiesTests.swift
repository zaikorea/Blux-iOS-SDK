import XCTest
@testable import BluxClient

/// 서버 `/update-properties` body의 user_properties 객체와 매칭.
/// 모든 필드는 선택. snake_case 키 변환 정확성 검증.
final class UserPropertiesTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func testInitWithDefaultsHasAllNil() {
        let props = UserProperties()
        XCTAssertNil(props.phoneNumber)
        XCTAssertNil(props.emailAddress)
        XCTAssertNil(props.gender)
        XCTAssertNil(props.age)
    }

    func testInitWithAllValues() {
        let props = UserProperties(
            phoneNumber: "010-1234-5678",
            emailAddress: "test@blux.ai",
            marketingNotificationConsent: true,
            marketingNotificationSmsConsent: false,
            marketingNotificationEmailConsent: true,
            marketingNotificationPushConsent: false,
            marketingNotificationKakaoConsent: true,
            nighttimeNotificationConsent: false,
            isAllNotificationBlocked: false,
            age: 28,
            gender: .female
        )

        XCTAssertEqual(props.phoneNumber, "010-1234-5678")
        XCTAssertEqual(props.emailAddress, "test@blux.ai")
        XCTAssertEqual(props.marketingNotificationConsent, true)
        XCTAssertEqual(props.gender, .female)
        XCTAssertEqual(props.age, 28)
    }

    func testEncodingUsesSnakeCaseKeys() throws {
        let props = UserProperties(
            phoneNumber: "010",
            marketingNotificationConsent: true,
            marketingNotificationSmsConsent: false,
            marketingNotificationEmailConsent: true,
            marketingNotificationPushConsent: false,
            marketingNotificationKakaoConsent: true,
            nighttimeNotificationConsent: false,
            isAllNotificationBlocked: true,
            age: 30,
            gender: .male
        )
        let data = try encoder.encode(props)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["phone_number"] as? String, "010")
        XCTAssertEqual(dict["marketing_notification_consent"] as? Bool, true)
        XCTAssertEqual(dict["marketing_notification_sms_consent"] as? Bool, false)
        XCTAssertEqual(dict["marketing_notification_email_consent"] as? Bool, true)
        XCTAssertEqual(dict["marketing_notification_push_consent"] as? Bool, false)
        XCTAssertEqual(dict["marketing_notification_kakao_consent"] as? Bool, true)
        XCTAssertEqual(dict["nighttime_notification_consent"] as? Bool, false)
        XCTAssertEqual(dict["is_all_notification_blocked"] as? Bool, true)
        XCTAssertEqual(dict["age"] as? Int, 30)
        XCTAssertEqual(dict["gender"] as? String, "male")
    }

    func testEncodingOmitsNilFields() throws {
        let props = UserProperties(emailAddress: "only@blux.ai")
        let data = try encoder.encode(props)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["email_address"] as? String, "only@blux.ai")
        XCTAssertNil(dict["phone_number"])
        XCTAssertNil(dict["age"])
        XCTAssertNil(dict["gender"])
    }

    func testGenderRawValues() {
        XCTAssertEqual(UserProperties.Gender.male.rawValue, "male")
        XCTAssertEqual(UserProperties.Gender.female.rawValue, "female")
    }

    func testGenderRoundTrip() throws {
        for gender in [UserProperties.Gender.male, .female] {
            let data = try encoder.encode(["g": gender])
            let decoded = try decoder.decode([String: UserProperties.Gender].self, from: data)
            XCTAssertEqual(decoded["g"], gender)
        }
    }

    func testRoundTripOfFullProperties() throws {
        let original = UserProperties(
            phoneNumber: "010",
            emailAddress: "x@y",
            age: 21,
            gender: .female
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UserProperties.self, from: data)
        XCTAssertEqual(decoded.phoneNumber, "010")
        XCTAssertEqual(decoded.emailAddress, "x@y")
        XCTAssertEqual(decoded.age, 21)
        XCTAssertEqual(decoded.gender, .female)
    }
}
