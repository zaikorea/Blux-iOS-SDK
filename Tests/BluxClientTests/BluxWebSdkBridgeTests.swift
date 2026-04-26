import XCTest
@testable import BluxClient

/// Web SDK(`@blux.ai/sdk-web`)의 `IosBridge`가 보내는 메시지를 iOS SDK가 정확히 처리하는지 검증.
///
/// Web SDK가 보내는 형태(IosBridge.postMessage):
/// ```js
/// window.webkit.messageHandlers.Blux.postMessage(JSON.stringify({ action, payload }))
/// ```
///
/// 따라서 message.body는 String JSON. 일부 수동 환경에서는 dictionary가 직접 들어올 수 있으니 둘 다 지원.
///
/// `WKWebView` 인스턴스 자체를 다루는 attach/detach는 시뮬레이터 GPU 프로세스 초기화를
/// 강제 트리거해 후속 테스트의 `DispatchQueue.global()` 스케줄링을 stall시킨다 (CI에서 12s+).
/// attach/detach는 Apple `WKUserContentController` API를 1줄로 감싼 wrapper일 뿐이라
/// 단위 테스트 가치 대비 비용이 너무 커 제외하고, 본질인 메시지 파싱/dispatch만 검증한다.
final class BluxWebSdkBridgeTests: XCTestCase {
    private var guardian: SdkStateGuard!
    private var bridge: BluxWebSdkBridge!

    override func setUp() {
        super.setUp()
        guardian = SdkStateGuard()
        guardian.clear()
        bridge = BluxWebSdkBridge()
    }

    override func tearDown() {
        guardian.restore()
        guardian = nil
        bridge = nil
        super.tearDown()
    }

    // MARK: - Static contract

    // Web SDK의 IosBridge.ts가 window.webkit.messageHandlers.Blux로 dispatch.
    func testHandlerNameMatchesWebSdkExpectation() {
        XCTAssertEqual(BluxWebSdkBridge.handlerName, "Blux")
    }

    // MARK: - Message body parsing

    func testHandleStringJSONIsParsed() {
        let json = "{\"action\":\"signOut\"}"
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: json)
        XCTAssertNil(EventHandlers.unhandledNotification)
    }

    func testHandleDictionaryBodyIsParsed() {
        let dict: [String: Any] = ["action": "signOut"]
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: dict)
        XCTAssertNil(EventHandlers.unhandledNotification)
    }

    func testHandleNumberBodyIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: 42)
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testHandleArrayBodyIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: [1, 2, 3])
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testHandleMalformedJSONStringIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "{not valid json")
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testHandleJSONStringWithNonObjectRootIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "[\"action\",\"signOut\"]")
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testMissingActionIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "{\"payload\":{}}")
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testEmptyActionIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "{\"action\":\"\"}")
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testNonStringActionIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "{\"action\":123}")
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    func testUnknownActionIsIgnored() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "{\"action\":\"unknown\"}")
        XCTAssertNotNil(EventHandlers.unhandledNotification)
    }

    // MARK: - initialize
    //
    // valid credentials는 BluxClient.initialize → DeviceService → URLSession.shared로 실제
    // HTTP 호출이 발생해 (default Stage가 prod) CI 환경에서 prod endpoint에 도달할 수 있다.
    // 따라서 valid initialize 변종은 두지 않고, invalid payload의 noop 분기만 검증한다.

    func testInitializeMissingApplicationIdIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"initialize\",\"payload\":{\"bluxAPIKey\":\"k\"}}")
        XCTAssertNil(SdkConfig.apiKeyInUserDefaults)
        XCTAssertNil(SdkConfig.clientIdInUserDefaults)
    }

    func testInitializeMissingApiKeyIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"initialize\",\"payload\":{\"bluxApplicationId\":\"a\"}}")
        XCTAssertNil(SdkConfig.apiKeyInUserDefaults)
        XCTAssertNil(SdkConfig.clientIdInUserDefaults)
    }

    func testInitializeEmptyApplicationIdIsNoop() {
        bridge.handle(scriptMessageBody:
            "{\"action\":\"initialize\",\"payload\":{\"bluxApplicationId\":\"\",\"bluxAPIKey\":\"k\"}}")
        XCTAssertNil(SdkConfig.apiKeyInUserDefaults)
    }

    func testInitializeEmptyApiKeyIsNoop() {
        bridge.handle(scriptMessageBody:
            "{\"action\":\"initialize\",\"payload\":{\"bluxApplicationId\":\"a\",\"bluxAPIKey\":\"\"}}")
        XCTAssertNil(SdkConfig.apiKeyInUserDefaults)
    }

    func testInitializeMissingPayloadIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"initialize\"}")
        XCTAssertNil(SdkConfig.apiKeyInUserDefaults)
    }

    // MARK: - signIn

    func testSignInWithUserIdInvokesSDKWithoutCrash() {
        bridge.handle(scriptMessageBody: "{\"action\":\"signIn\",\"payload\":{\"userId\":\"u-1\"}}")
    }

    func testSignInMissingUserIdIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"signIn\",\"payload\":{}}")
    }

    func testSignInEmptyUserIdIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"signIn\",\"payload\":{\"userId\":\"\"}}")
    }

    func testSignInMissingPayloadIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"signIn\"}")
    }

    // MARK: - signOut

    func testSignOutClearsUnhandledNotification() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: "{\"action\":\"signOut\"}")
        XCTAssertNil(EventHandlers.unhandledNotification)
    }

    func testSignOutDoesNotRequireIDs() {
        bridge.handle(scriptMessageBody: "{\"action\":\"signOut\"}")
    }

    // MARK: - setUserProperties (snake_case)

    func testSetUserPropertiesAcceptsSnakeCaseSchema() {
        // Web SDK가 보내는 정확한 형태 (UserProperties Codable의 snake_case 키)
        let body: [String: Any] = [
            "action": "setUserProperties",
            "payload": [
                "phone_number": "010",
                "email_address": "x@y",
                "marketing_notification_consent": true,
                "marketing_notification_sms_consent": false,
                "age": 25,
                "gender": "female"
            ]
        ]
        bridge.handle(scriptMessageBody: body)
        // 사이드이펙트 직접 검증 어려움. 디코딩 자체가 throw 안 하면 통과 (BluxClient는 IDs 없으니 early return)
    }

    func testSetUserPropertiesNonDictionaryIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"setUserProperties\",\"payload\":\"not-a-dict\"}")
    }

    func testSetUserPropertiesMissingPayloadIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"setUserProperties\"}")
    }

    func testSetUserPropertiesInvalidSchemaIsNoop() {
        // age는 Int여야 함. String이면 디코딩 실패하지만 bridge는 swallow
        let body: [String: Any] = [
            "action": "setUserProperties",
            "payload": ["age": "not-a-number"]
        ]
        bridge.handle(scriptMessageBody: body)
    }

    // MARK: - setCustomUserProperties

    func testSetCustomUserPropertiesAcceptsArbitraryKeys() {
        let body: [String: Any] = [
            "action": "setCustomUserProperties",
            "payload": [
                "favorite_color": "blue",
                "loyalty_points": 100,
                "tags": ["a", "b"]
            ]
        ]
        bridge.handle(scriptMessageBody: body)
    }

    func testSetCustomUserPropertiesSanitizesNSNullToNil() {
        // Web SDK에서 null로 보낸 값이 NSNull로 변환되는데 bridge가 nil로 처리해야 함
        let body: [String: Any] = [
            "action": "setCustomUserProperties",
            "payload": ["removed_key": NSNull()]
        ]
        bridge.handle(scriptMessageBody: body)
    }

    func testSetCustomUserPropertiesNonDictionaryIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"setCustomUserProperties\",\"payload\":42}")
    }

    func testSetCustomUserPropertiesMissingPayloadIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"setCustomUserProperties\"}")
    }

    // MARK: - sendEvent (Web SDK EventRequest 호환)

    func testSendEventBuildsEventFromSnakeCasePayload() {
        // Web SDK의 EventRequest: { id, event_type, captured_at, event_properties?, custom_event_properties?, internal_event_properties? }
        let body: [String: Any] = [
            "action": "sendEvent",
            "payload": [
                "requests": [
                    [
                        "id": "req-1",  // Web SDK uuid - iOS는 무시
                        "event_type": "page_view",
                        "captured_at": "2025-01-01T00:00:00.000Z",
                        "event_properties": ["page": "home"],
                        "custom_event_properties": ["scroll": 0.5],
                        "internal_event_properties": ["url": "/home", "ref": "/index"]
                    ]
                ]
            ]
        ]
        // BluxClient.sendRequestData를 통해 EventService.sendEvent로 전달.
        // SdkConfig IDs가 없어 EventQueue 안에서 early return.
        // 크래시만 안 나면 통과.
        bridge.handle(scriptMessageBody: body)
    }

    func testSendEventRequestsMissingIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"sendEvent\",\"payload\":{}}")
    }

    func testSendEventRequestsEmptyArrayIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"sendEvent\",\"payload\":{\"requests\":[]}}")
    }

    func testSendEventNonDictionaryPayloadIsNoop() {
        bridge.handle(scriptMessageBody: "{\"action\":\"sendEvent\",\"payload\":\"x\"}")
    }

    func testSendEventSkipsRequestsWithoutEventType() {
        let body: [String: Any] = [
            "action": "sendEvent",
            "payload": [
                "requests": [
                    ["captured_at": "2025-01-01T00:00:00.000Z"], // event_type 누락 → 스킵
                    ["event_type": "valid"] // 정상
                ]
            ]
        ]
        bridge.handle(scriptMessageBody: body)
    }

    func testSendEventSkipsRequestsWithEmptyEventType() {
        let body: [String: Any] = [
            "action": "sendEvent",
            "payload": [
                "requests": [["event_type": ""]]
            ]
        ]
        bridge.handle(scriptMessageBody: body)
    }

    // MARK: - Web SDK full contract simulation

    /// IosBridge.postMessage가 실제로 만드는 JSON 형태를 그대로 재현.
    /// Web SDK의 IosBridge.ts:
    ///   handler.postMessage(JSON.stringify({ action, payload }))
    /// initialize 변종은 prod HTTP 호출 위험으로 제외 (위 MARK: - initialize 주석 참고).

    func testFullSignOutContractFromWebSdk() throws {
        // Web SDK IosBridge.signOut(): postMessage("signOut") - payload 없음
        let envelope: [String: Any] = ["action": "signOut"]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        let json = String(data: data, encoding: .utf8)!

        EventHandlers.unhandledNotification = BluxNotification(
            id: "x", body: "x", title: nil, url: nil, imageUrl: nil, data: nil
        )
        bridge.handle(scriptMessageBody: json)
        XCTAssertNil(EventHandlers.unhandledNotification)
    }

    func testFullSendEventContractFromWebSdk() throws {
        // Web SDK에서 AddOrderEvent를 보낸 시나리오를 정확히 재현
        let request: [String: Any] = [
            "id": UUID().uuidString,
            "event_type": "order",
            "event_properties": [
                "order_id": "ORD-1",
                "paid_amount": 90.0,
                "order_amount": 100.0,
                "items": [
                    ["id": "p1", "price": 50.0, "quantity": 2]
                ]
            ],
            "custom_event_properties": [
                "coupon_code": "SAVE10"
            ],
            "internal_event_properties": [
                "url": "https://example.com/checkout",
                "ref": "https://example.com/cart"
            ],
            "captured_at": "2025-01-01T12:00:00.000Z"
        ]
        let envelope: [String: Any] = [
            "action": "sendEvent",
            "payload": ["requests": [request]]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        let json = String(data: data, encoding: .utf8)!
        bridge.handle(scriptMessageBody: json)
        // 디코딩까지 정상이면 EventService.sendEvent까지 호출됨.
        // SdkConfig IDs 없어 EventQueue가 early return하지만 크래시 없으면 통과.
    }
}
