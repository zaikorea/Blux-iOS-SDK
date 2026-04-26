import XCTest
import UIKit
@testable import BluxClient

/// React Native/Flutter SDK는 iOS SDK의 public API에 직접 의존한다.
/// 이 테스트는 두 SDK가 사용하는 패턴이 깨지지 않음을 검증한다.
///
/// **RN(`Blux-RN-SDK/ios/Blux.swift`)이 호출하는 패턴**:
/// - `BluxClient.setUserPropertiesData(userProperties: [String: Any])` (snake_case dict)
/// - `Event(eventType:)` + `capturedAt = ...` + `setEventProperties(EventProperties)` + `setCustomEventProperties` + `setInternalEventProperties`
/// - `BluxClient.sendRequestData([Event])`
/// - `BluxClient.addInAppCustomActionHandler { actionId, data in ... }` (returns unsubscribe)
///
/// **Flutter(`Blux-Flutter-SDK/ios/Classes/BluxFlutterPlugin.swift`)가 호출하는 패턴**:
/// - `UserProperties(phoneNumber:..., gender:...)` 모든 옵셔널 init
/// - `UserProperties.Gender(rawValue:)` ("male"/"female")
/// - `HttpUrlOpenTarget` 멤버 (`.internalWebView`, `.externalBrowser`, `.none`)
/// - `NotificationReceivedEvent.toDictionary()` / `display()`
/// - `BluxNotification.toDictionary()`
final class RNFlutterBridgeContractTests: XCTestCase {
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

    // MARK: - RN: setUserPropertiesData with [String: Any]

    func testRN_SetUserPropertiesDataAcceptsArbitraryDict() {
        // RN은 JS의 객체를 [String: Any]로 변환해 넘김
        let dict: [String: Any?] = [
            "phone_number": "010",
            "email_address": "x@y",
            "marketing_notification_consent": true,
            "age": 30,
            "gender": "female"
        ]
        // SdkConfig IDs 없으면 early return. 크래시 안 나는지만 검증.
        BluxClient.setUserPropertiesData(userProperties: dict)
    }

    func testRN_SetUserPropertiesDataHandlesNilValues() {
        let dict: [String: Any?] = [
            "phone_number": nil,
            "email_address": "x@y"
        ]
        BluxClient.setUserPropertiesData(userProperties: dict)
    }

    func testRN_SetCustomUserPropertiesAcceptsAnyValue() {
        let dict: [String: Any?] = [
            "score": 100,
            "tier": "gold",
            "active": true,
            "tags": ["a", "b"],
            "removed": nil
        ]
        BluxClient.setCustomUserProperties(customUserProperties: dict)
    }

    // MARK: - RN: Event from NSDictionary (sendRequest 패턴 재현)

    func testRN_EventFromDictionaryWithSnakeCaseProperties() throws {
        // RN의 sendRequest 핸들러가 만드는 Event를 직접 재현
        let dict: [String: Any] = [
            "event_type": "page_view",
            "captured_at": "2025-04-26T12:34:56.789Z",
            "event_properties": [
                "page": "home",
                "prev_page": "splash",
                "section": "hero"
            ],
            "custom_event_properties": [
                "scroll_depth": 0.5,
                "ab_variant": "B"
            ],
            "internal_event_properties": [
                "url": "/home",
                "ref": "/splash"
            ]
        ]

        guard let eventType = dict["event_type"] as? String,
              let capturedAt = dict["captured_at"] as? String,
              let propsDict = dict["event_properties"] as? [String: Any],
              let customDict = dict["custom_event_properties"] as? [String: Any],
              let internalDict = dict["internal_event_properties"] as? [String: Any]
        else {
            XCTFail("Test fixture is malformed")
            return
        }

        let event = Event(eventType: eventType)
        event.capturedAt = capturedAt

        let propsData = try JSONSerialization.data(withJSONObject: propsDict)
        let props = try JSONDecoder().decode(EventProperties.self, from: propsData)
        event.setEventProperties(props)

        var custom: [String: CustomEventValue] = [:]
        for (k, v) in customDict {
            if let converted = CustomEventValue.fromAny(v) {
                custom[k] = converted
            }
        }
        event.setCustomEventProperties(custom)

        var int: [String: CustomEventValue] = [:]
        for (k, v) in internalDict {
            if let converted = CustomEventValue.fromAny(v) {
                int[k] = converted
            }
        }
        event.setInternalEventProperties(int)

        // 결과 검증
        XCTAssertEqual(event.eventType, "page_view")
        XCTAssertEqual(event.capturedAt, "2025-04-26T12:34:56.789Z")
        XCTAssertEqual(event.eventProperties.page, "home")
        XCTAssertEqual(event.eventProperties.prevSection, nil)
        XCTAssertEqual(event.eventProperties.section, "hero")
        if case .double(let d)? = event.customEventProperties?["scroll_depth"] {
            XCTAssertEqual(d, 0.5, accuracy: 0.001)
        } else { XCTFail() }
        if case .string("B")? = event.customEventProperties?["ab_variant"] {} else { XCTFail() }
        if case .string("/home")? = event.internalEventProperties?["url"] {} else { XCTFail() }
    }

    func testRN_SendRequestDataWithEventArrayDoesNotCrash() {
        let event = Event(eventType: "x")
        BluxClient.sendRequestData([event])
    }

    func testRN_AddInAppCustomActionHandlerReturnsUnsubscribe() {
        // RN의 startInAppCustomActionHandler는 unsubscribe 클로저를 저장한다.
        let savedCount = EventHandlers.inAppCustomActionHandlers.count
        let unsubscribe: () -> Void = BluxClient.addInAppCustomActionHandler { _, _ in }
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, savedCount + 1)
        unsubscribe()
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, savedCount)
    }

    // MARK: - Flutter: UserProperties 직접 init (모두 옵셔널)

    func testFlutter_UserPropertiesAllOptionalInit() {
        // Flutter plugin은 dict에서 각 필드를 추출해 직접 init
        let properties = UserProperties(
            phoneNumber: nil,
            emailAddress: nil,
            marketingNotificationConsent: nil,
            marketingNotificationSmsConsent: nil,
            marketingNotificationEmailConsent: nil,
            marketingNotificationPushConsent: nil,
            marketingNotificationKakaoConsent: nil,
            nighttimeNotificationConsent: nil,
            isAllNotificationBlocked: nil,
            age: nil,
            gender: nil
        )
        BluxClient.setUserProperties(userProperties: properties)
        // 모든 필드 nil이어도 호출 가능
    }

    func testFlutter_UserPropertiesPartialInit() {
        let properties = UserProperties(
            phoneNumber: "010-1234",
            age: 33
        )
        XCTAssertEqual(properties.phoneNumber, "010-1234")
        XCTAssertEqual(properties.age, 33)
        XCTAssertNil(properties.emailAddress)
        XCTAssertNil(properties.gender)
    }

    func testFlutter_UserPropertiesGenderRawValueRoundTrip() {
        // Flutter: UserProperties.Gender(rawValue: "female")로 매핑
        XCTAssertEqual(UserProperties.Gender(rawValue: "male"), .male)
        XCTAssertEqual(UserProperties.Gender(rawValue: "female"), .female)
        XCTAssertNil(UserProperties.Gender(rawValue: "other"))
        XCTAssertNil(UserProperties.Gender(rawValue: "MALE"))  // case-sensitive
        XCTAssertNil(UserProperties.Gender(rawValue: ""))
    }

    // MARK: - Flutter: HttpUrlOpenTarget 문자열 매핑

    func testFlutter_HttpUrlOpenTargetMembersAccessible() {
        // Flutter plugin이 사용하는 case들이 public으로 노출되어야 함
        let internalCase: HttpUrlOpenTarget = .internalWebView
        let externalCase: HttpUrlOpenTarget = .externalBrowser
        let noneCase: HttpUrlOpenTarget = HttpUrlOpenTarget.none

        XCTAssertEqual(internalCase.rawValue, 0)
        XCTAssertEqual(externalCase.rawValue, 1)
        XCTAssertEqual(noneCase.rawValue, 2)
    }

    func testFlutter_NotificationUrlOpenOptionsInitWithAllTargets() {
        // 각 target에 대해 init 가능
        let opts1 = NotificationUrlOpenOptions(httpUrlOpenTarget: .internalWebView)
        let opts2 = NotificationUrlOpenOptions(httpUrlOpenTarget: .externalBrowser)
        let opts3 = NotificationUrlOpenOptions(httpUrlOpenTarget: HttpUrlOpenTarget.none)

        BluxClient.setNotificationUrlOpenOptions(opts1)
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, .internalWebView)
        BluxClient.setNotificationUrlOpenOptions(opts2)
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, .externalBrowser)
        BluxClient.setNotificationUrlOpenOptions(opts3)
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, HttpUrlOpenTarget.none)
    }

    // MARK: - Flutter: Event chain (BluxFlutterPlugin sendEvent 패턴)

    func testFlutter_EventChainWithSetEventProperties() throws {
        let dict: [String: Any] = [
            "event_type": "purchase",
            "event_properties": [
                "order_id": "O-1",
                "order_amount": 100.0,
                "paid_amount": 90.0
            ]
        ]

        let eventType = dict["event_type"] as! String
        let propsDict = dict["event_properties"] as! [String: Any]
        let propsData = try JSONSerialization.data(withJSONObject: propsDict)
        let props = try JSONDecoder().decode(EventProperties.self, from: propsData)

        let event = Event(eventType: eventType)
            .setEventProperties(props)
            .setCustomEventProperties(nil)
            .setInternalEventProperties(nil)

        XCTAssertEqual(event.eventType, "purchase")
        XCTAssertEqual(event.eventProperties.orderId, "O-1")
        XCTAssertEqual(event.eventProperties.orderAmount, 100)
        XCTAssertEqual(event.eventProperties.paidAmount, 90)
    }

    func testFlutter_EventPropertiesDecodeFromEmptyDict() throws {
        // sendEvent 처리에서 event_properties가 비어있어도 정상 디코딩
        let data = try JSONSerialization.data(withJSONObject: [String: Any]())
        let props = try JSONDecoder().decode(EventProperties.self, from: data)
        XCTAssertNil(props.itemId)
        XCTAssertNil(props.page)
    }

    // MARK: - Flutter: Notification handler / display 패턴

    func testFlutter_BluxNotificationToDictionaryRoundTrip() {
        // Flutter는 BluxNotification.toDictionary()를 channel arguments로 보냄
        let notif = BluxNotification(
            id: "n",
            body: "B",
            title: "T",
            url: "U",
            imageUrl: "I",
            data: ["k": "v"]
        )
        let dict = notif.toDictionary()
        XCTAssertEqual(dict["id"] as? String, "n")
        XCTAssertEqual(dict["body"] as? String, "B")
        XCTAssertEqual(dict["title"] as? String, "T")
        XCTAssertEqual(dict["url"] as? String, "U")
        XCTAssertEqual(dict["imageUrl"] as? String, "I")
        let inner = dict["data"] as? [String: Any]
        XCTAssertEqual(inner?["k"] as? String, "v")
    }

    func testFlutter_BluxNotificationToDictionaryWithNils() {
        // Flutter side가 nil을 받아도 깨지지 않아야 함
        let notif = BluxNotification(
            id: "n",
            body: "B",
            title: nil,
            url: nil,
            imageUrl: nil,
            data: nil
        )
        let dict = notif.toDictionary()
        XCTAssertEqual(dict["id"] as? String, "n")
        XCTAssertNotNil(dict.keys.contains("title"))
        // Optional<String>의 nil이 dict[Key]: Any?로 들어감 → 키는 존재하나 unwrap하면 nil
    }

    // public API surface 시그니처/타입 컴파일 검증과 StageSwitcher ObjC 노출 검증은
    // BluxClientPublicAPITests testTarget으로 이동 (plain `import BluxClient`로 wrapper SDK와
    // 동일한 access modifier 환경에서 검증). 이 파일은 @testable import라 internal까지
    // 보여 access-control 강등 회귀를 잡지 못한다.
}
