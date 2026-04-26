import XCTest
@testable import BluxClient

final class AddOrderEventTests: XCTestCase {
    func testBuildEmptyBuilderProducesOrderEvent() throws {
        let req = try AddOrderEvent.Builder().build()
        XCTAssertEqual(req.events.count, 1)
        XCTAssertEqual(req.events[0].eventType, "order")
    }

    func testBuildWithOrderId() throws {
        let req = try AddOrderEvent.Builder()
            .orderId("ORD-1")
            .build()
        XCTAssertEqual(req.events[0].eventProperties.orderId, "ORD-1")
    }

    func testBuildWithAmounts() throws {
        let req = try AddOrderEvent.Builder()
            .orderAmount(100.0)
            .paidAmount(80.0)
            .build()
        XCTAssertEqual(req.events[0].eventProperties.orderAmount, 100.0)
        XCTAssertEqual(req.events[0].eventProperties.paidAmount, 80.0)
    }

    func testBuildWithItems() throws {
        let req = try AddOrderEvent.Builder()
            .addItem(id: "a", price: 10, quantity: 2)
            .addItem(id: "b", price: 20, quantity: 1)
            .build()
        XCTAssertEqual(req.events[0].eventProperties.items?.count, 2)
        XCTAssertEqual(req.events[0].eventProperties.items?[0].id, "a")
        XCTAssertEqual(req.events[0].eventProperties.items?[1].quantity, 1)
    }

    func testBuildWithItemCustomProperties() throws {
        let req = try AddOrderEvent.Builder()
            .addItem(id: "a", price: 10, quantity: 1, customEventProperties: ["color": .string("red")])
            .build()
        let item = req.events[0].eventProperties.items?[0]
        if case .string("red")? = item?.customEventProperties?["color"] {} else {
            XCTFail("color custom prop missing")
        }
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddOrderEvent.Builder()
            .customEventProperties(["coupon": .string("SAVE10")])
            .build()
        if case .string("SAVE10")? = req.events[0].customEventProperties?["coupon"] {} else {
            XCTFail()
        }
    }

    func testEmptyOrderIdThrows() {
        XCTAssertThrowsError(try AddOrderEvent.Builder().orderId("").build())
    }

    func testFluentChainingReturnsSameBuilder() throws {
        let builder = AddOrderEvent.Builder()
        let returned = builder
            .orderId("X")
            .orderAmount(1)
            .paidAmount(1)
        XCTAssertTrue(returned === builder, "chaining should return self for method chaining")
    }

    func testItemEncodingMatchesContract() throws {
        let item = AddOrderEvent.Item(id: "p1", price: 99.99, quantity: 3)
        let data = try JSONEncoder().encode(item)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["id"] as? String, "p1")
        XCTAssertEqual(dict["price"] as? Double, 99.99)
        XCTAssertEqual(dict["quantity"] as? Int, 3)
    }

    func testCompleteOrderEncodes() throws {
        let req = try AddOrderEvent.Builder()
            .orderId("O")
            .orderAmount(200)
            .paidAmount(180)
            .addItem(id: "a", price: 100, quantity: 2)
            .customEventProperties(["promo": .bool(true)])
            .build()

        let payload = req.getPayload()
        XCTAssertEqual(payload.count, 1)
        let data = try JSONEncoder().encode(payload[0])
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["event_type"] as? String, "order")
        let props = dict["event_properties"] as! [String: Any]
        XCTAssertEqual(props["order_id"] as? String, "O")
        XCTAssertEqual(props["order_amount"] as? Double, 200)
        XCTAssertEqual(props["paid_amount"] as? Double, 180)
    }
}
