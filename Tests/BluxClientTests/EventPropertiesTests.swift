import XCTest
@testable import BluxClient

final class EventPropertiesTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func testAllFieldsAreOptionalByDefault() {
        let props = EventProperties()
        XCTAssertNil(props.itemId)
        XCTAssertNil(props.section)
        XCTAssertNil(props.prevSection)
        XCTAssertNil(props.recommendationId)
        XCTAssertNil(props.price)
        XCTAssertNil(props.orderId)
        XCTAssertNil(props.rating)
        XCTAssertNil(props.prevPage)
        XCTAssertNil(props.page)
        XCTAssertNil(props.position)
        XCTAssertNil(props.orderAmount)
        XCTAssertNil(props.paidAmount)
        XCTAssertNil(props.items)
    }

    func testSnakeCaseEncoding() throws {
        let props = EventProperties()
        props.itemId = "i1"
        props.prevSection = "p"
        props.recommendationId = "r"
        props.orderId = "o"
        props.prevPage = "pp"
        props.orderAmount = 1
        props.paidAmount = 2

        let data = try encoder.encode(props)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["item_id"] as? String, "i1")
        XCTAssertEqual(dict["prev_section"] as? String, "p")
        XCTAssertEqual(dict["recommendation_id"] as? String, "r")
        XCTAssertEqual(dict["order_id"] as? String, "o")
        XCTAssertEqual(dict["prev_page"] as? String, "pp")
        XCTAssertEqual(dict["order_amount"] as? Double, 1)
        XCTAssertEqual(dict["paid_amount"] as? Double, 2)
    }

    func testItemsEncodingShape() throws {
        let props = EventProperties()
        props.items = [AddOrderEvent.Item(id: "a", price: 100, quantity: 2)]
        let data = try encoder.encode(props)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let items = dict["items"] as! [[String: Any]]
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0]["id"] as? String, "a")
        XCTAssertEqual(items[0]["price"] as? Double, 100)
        XCTAssertEqual(items[0]["quantity"] as? Int, 2)
    }

    func testItemEncodingIncludesCustomProps() throws {
        let item = AddOrderEvent.Item(
            id: "x",
            price: 1,
            quantity: 1,
            customEventProperties: ["color": .string("blue")]
        )
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let custom = dict["custom_event_properties"] as! [String: Any]
        XCTAssertEqual(custom["color"] as? String, "blue")
    }

    func testItemEncodingOmitsNilCustomProps() throws {
        let item = AddOrderEvent.Item(id: "x", price: 1, quantity: 1)
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNil(dict["custom_event_properties"])
    }

    func testRoundTrip() throws {
        let props = EventProperties()
        props.itemId = "id"
        props.price = 1.5
        props.position = 7

        let data = try encoder.encode(props)
        let decoded = try decoder.decode(EventProperties.self, from: data)
        XCTAssertEqual(decoded.itemId, "id")
        XCTAssertEqual(decoded.price, 1.5)
        XCTAssertEqual(decoded.position, 7)
    }
}
