import XCTest
@testable import BluxClient

/// Event 모델은 서버 `/v2/collect-events`의 `events[]` 요소와 매칭.
/// 서버 schema: { event_type (필수), captured_at (필수), event_properties?, custom_event_properties?, internal_event_properties? }
/// SDK는 추가로 blux_id, device_id, user_id, session_id를 같이 보냄 (Event level은 서버 wrapper의 device_id로도 식별됨).
final class EventTests: XCTestCase {
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

    // MARK: - Initialization

    func testInitWithEventTypeStoresType() {
        let event = Event(eventType: "page_view")
        XCTAssertEqual(event.eventType, "page_view")
    }

    func testInitGeneratesISO8601CapturedAt() {
        let event = Event(eventType: "visit")
        XCTAssertNotNil(ISO8601DateFormatter().date(from: event.capturedAt),
                        "capturedAt must be ISO8601 parseable")
    }

    func testInitInheritsSdkConfigIds() {
        SdkConfig.bluxIdInUserDefaults = "blux-1"
        SdkConfig.deviceIdInUserDefaults = "device-1"
        SdkConfig.userIdInUserDefaults = "user-1"

        let event = Event(eventType: "x")
        XCTAssertEqual(event.bluxId, "blux-1")
        XCTAssertEqual(event.deviceId, "device-1")
        XCTAssertEqual(event.userId, "user-1")
    }

    func testInitInheritsSessionId() {
        SdkConfig.sessionId = "fixed-session"
        let event = Event(eventType: "x")
        XCTAssertEqual(event.sessionId, "fixed-session")
    }

    func testInitWhenIdsAreNil() {
        let event = Event(eventType: "x")
        XCTAssertNil(event.bluxId)
        XCTAssertNil(event.deviceId)
        XCTAssertNil(event.userId)
        XCTAssertNotNil(event.sessionId)
    }

    func testInitDefaultsToEmptyEventProperties() {
        let event = Event(eventType: "x")
        XCTAssertNil(event.eventProperties.itemId)
        XCTAssertNil(event.eventProperties.price)
    }

    // MARK: - Setters: itemId

    func testSetItemIdValid() throws {
        let event = Event(eventType: "x")
        try event.setItemId("item-123")
        XCTAssertEqual(event.eventProperties.itemId, "item-123")
    }

    func testSetItemIdEmptyThrows() {
        let event = Event(eventType: "x")
        XCTAssertThrowsError(try event.setItemId(""))
    }

    func testSetItemIdTooLongThrows() {
        let longId = String(repeating: "a", count: 501)
        let event = Event(eventType: "x")
        XCTAssertThrowsError(try event.setItemId(longId))
    }

    func testSetItemId500CharsAllowed() throws {
        let id500 = String(repeating: "a", count: 500)
        let event = Event(eventType: "x")
        try event.setItemId(id500)
        XCTAssertEqual(event.eventProperties.itemId?.count, 500)
    }

    // MARK: - Setters: price

    func testSetPriceValid() throws {
        let event = Event(eventType: "x")
        try event.setPrice(1000)
        XCTAssertEqual(event.eventProperties.price, 1000)
    }

    func testSetPriceZeroAllowed() throws {
        let event = Event(eventType: "x")
        try event.setPrice(0)
        XCTAssertEqual(event.eventProperties.price, 0)
    }

    func testSetPriceNegativeThrows() {
        let event = Event(eventType: "x")
        XCTAssertThrowsError(try event.setPrice(-0.01))
    }

    func testSetPriceNilLeavesUnset() throws {
        let event = Event(eventType: "x")
        try event.setPrice(nil)
        XCTAssertNil(event.eventProperties.price)
    }

    // MARK: - Setters: orderId, page

    func testSetOrderIdValid() throws {
        let event = Event(eventType: "x")
        try event.setOrderId("ORD-001")
        XCTAssertEqual(event.eventProperties.orderId, "ORD-001")
    }

    func testSetOrderIdEmptyThrows() {
        let event = Event(eventType: "x")
        XCTAssertThrowsError(try event.setOrderId(""))
    }

    func testSetOrderIdNilLeavesUnset() throws {
        let event = Event(eventType: "x")
        try event.setOrderId(nil)
        XCTAssertNil(event.eventProperties.orderId)
    }

    func testSetPageValid() throws {
        let event = Event(eventType: "x")
        try event.setPage("home")
        XCTAssertEqual(event.eventProperties.page, "home")
    }

    func testSetPageEmptyThrows() {
        let event = Event(eventType: "x")
        XCTAssertThrowsError(try event.setPage(""))
    }

    // MARK: - Setters: rating, amounts (no validation)

    func testSetRatingPersists() throws {
        let event = Event(eventType: "x")
        try event.setRating(4.5)
        XCTAssertEqual(event.eventProperties.rating, 4.5)
    }

    func testSetRatingNilLeavesUnset() throws {
        let event = Event(eventType: "x")
        try event.setRating(nil)
        XCTAssertNil(event.eventProperties.rating)
    }

    func testSetOrderAmountPersists() throws {
        let event = Event(eventType: "x")
        try event.setOrderAmount(99.99)
        XCTAssertEqual(event.eventProperties.orderAmount, 99.99)
    }

    func testSetPaidAmountPersists() throws {
        let event = Event(eventType: "x")
        try event.setPaidAmount(50.0)
        XCTAssertEqual(event.eventProperties.paidAmount, 50.0)
    }

    // MARK: - Setters: items

    func testSetItemsPersists() throws {
        let event = Event(eventType: "x")
        let items = [AddOrderEvent.Item(id: "a", price: 1, quantity: 1)]
        try event.setItems(items)
        XCTAssertEqual(event.eventProperties.items?.count, 1)
        XCTAssertEqual(event.eventProperties.items?.first?.id, "a")
    }

    func testSetItemsNilLeavesUnset() throws {
        let event = Event(eventType: "x")
        try event.setItems(nil)
        XCTAssertNil(event.eventProperties.items)
    }

    // MARK: - Setter chaining is fluent

    func testFluentChaining() throws {
        let event = try Event(eventType: "order")
            .setOrderId("O-1")
            .setOrderAmount(100)
            .setPaidAmount(80)

        XCTAssertEqual(event.eventProperties.orderId, "O-1")
        XCTAssertEqual(event.eventProperties.orderAmount, 100)
        XCTAssertEqual(event.eventProperties.paidAmount, 80)
    }

    // MARK: - Custom / Internal properties

    func testSetCustomEventProperties() {
        let event = Event(eventType: "x")
        event.setCustomEventProperties(["k": .string("v")])
        XCTAssertNotNil(event.customEventProperties)
        if case .string("v")? = event.customEventProperties?["k"] {} else {
            XCTFail("custom property k mismatch")
        }
    }

    func testSetCustomEventPropertiesNilClears() {
        let event = Event(eventType: "x")
        event.setCustomEventProperties(["k": .int(1)])
        event.setCustomEventProperties(nil)
        XCTAssertNil(event.customEventProperties)
    }

    func testSetInternalEventProperties() {
        let event = Event(eventType: "x")
        event.setInternalEventProperties(["url": .string("/foo")])
        if case .string("/foo")? = event.internalEventProperties?["url"] {} else {
            XCTFail()
        }
    }

    // MARK: - setEventProperties

    func testSetEventPropertiesReplacesContainer() {
        let event = Event(eventType: "x")
        let props = EventProperties()
        props.itemId = "from-replacement"
        event.setEventProperties(props)
        XCTAssertEqual(event.eventProperties.itemId, "from-replacement")
    }

    func testSetEventPropertiesNilLeavesExisting() throws {
        let event = Event(eventType: "x")
        try event.setItemId("kept")
        event.setEventProperties(nil)
        XCTAssertEqual(event.eventProperties.itemId, "kept")
    }

    // MARK: - Encoding (서버 contract 검증)

    func testEncodingProducesSnakeCaseKeys() throws {
        SdkConfig.bluxIdInUserDefaults = "B"
        SdkConfig.deviceIdInUserDefaults = "D"
        SdkConfig.userIdInUserDefaults = "U"
        SdkConfig.sessionId = "S"

        let event = try Event(eventType: "page_view").setPage("home")
        let data = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["event_type"] as? String, "page_view")
        XCTAssertEqual(dict["blux_id"] as? String, "B")
        XCTAssertEqual(dict["device_id"] as? String, "D")
        XCTAssertEqual(dict["user_id"] as? String, "U")
        XCTAssertEqual(dict["session_id"] as? String, "S")
        XCTAssertNotNil(dict["captured_at"])
        XCTAssertNotNil(dict["event_properties"])

        let props = dict["event_properties"] as! [String: Any]
        XCTAssertEqual(props["page"] as? String, "home")
    }

    func testEncodingOmitsNilCustomAndInternalProps() throws {
        let event = Event(eventType: "x")
        let data = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        // JSONEncoder의 기본 동작: nil은 키 누락 (Swift Optional)
        XCTAssertNil(dict["custom_event_properties"])
        XCTAssertNil(dict["internal_event_properties"])
    }

    func testEncodingIncludesCustomEventProperties() throws {
        let event = Event(eventType: "x")
        event.setCustomEventProperties(["color": .string("red"), "qty": .int(3)])
        let data = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let custom = dict["custom_event_properties"] as! [String: Any]
        XCTAssertEqual(custom["color"] as? String, "red")
        XCTAssertEqual(custom["qty"] as? Int, 3)
    }

    // MARK: - Description

    func testDescriptionContainsEventType() {
        let event = Event(eventType: "page_view")
        XCTAssertTrue(event.description.contains("page_view"))
    }

    func testDescriptionSkipsNullStrings() {
        // bluxId가 "null" 문자열이면 description에서 빠짐 (서버에서 null sentinel 보낼 때 노이즈 방지)
        let event = Event(eventType: "x")
        event.bluxId = "null"
        XCTAssertFalse(event.description.contains("bluxId: null"))
    }

    func testDescriptionShowsCustomProps() {
        let event = Event(eventType: "x")
        event.setCustomEventProperties(["k": .string("v")])
        XCTAssertTrue(event.description.contains("customEventProperties"))
    }
}
