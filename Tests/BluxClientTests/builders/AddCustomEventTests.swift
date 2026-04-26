import XCTest
@testable import BluxClient

final class AddCustomEventTests: XCTestCase {
    func testBuildEmptyBuilderUsesProvidedEventType() throws {
        let req = try AddCustomEvent.Builder(eventType: "wishlist_add").build()
        XCTAssertEqual(req.events[0].eventType, "wishlist_add")
    }

    func testBuildWithAllFields() throws {
        let req = try AddCustomEvent.Builder(eventType: "search")
            .itemId("i")
            .orderId("o")
            .orderAmount(100)
            .paidAmount(90)
            .rating(4.5)
            .page("results")
            .addItem(id: "p1", price: 10, quantity: 1)
            .customEventProperties(["q": .string("shoes")])
            .build()

        let event = req.events[0]
        XCTAssertEqual(event.eventType, "search")
        XCTAssertEqual(event.eventProperties.itemId, "i")
        XCTAssertEqual(event.eventProperties.orderId, "o")
        XCTAssertEqual(event.eventProperties.orderAmount, 100)
        XCTAssertEqual(event.eventProperties.paidAmount, 90)
        XCTAssertEqual(event.eventProperties.rating, 4.5)
        XCTAssertEqual(event.eventProperties.page, "results")
        XCTAssertEqual(event.eventProperties.items?.count, 1)
    }

    func testInvalidItemIdThrows() {
        XCTAssertThrowsError(try AddCustomEvent.Builder(eventType: "x").itemId("").build())
    }

    func testInvalidOrderIdThrows() {
        XCTAssertThrowsError(try AddCustomEvent.Builder(eventType: "x").orderId("").build())
    }

    func testInvalidPageThrows() {
        XCTAssertThrowsError(try AddCustomEvent.Builder(eventType: "x").page("").build())
    }

    func testEmptyEventTypeIsAllowed() throws {
        // Builder는 eventType 자체에 대한 검증은 하지 않음 (자유로움)
        let req = try AddCustomEvent.Builder(eventType: "").build()
        XCTAssertEqual(req.events[0].eventType, "")
    }
}
