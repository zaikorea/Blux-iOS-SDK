import XCTest
@testable import BluxClient

final class AddCartaddEventTests: XCTestCase {
    func testBuildProducesCartaddEvent() throws {
        let req = try AddCartaddEvent.Builder(itemId: "p1").build()
        XCTAssertEqual(req.events.count, 1)
        XCTAssertEqual(req.events[0].eventType, "cartadd")
        XCTAssertEqual(req.events[0].eventProperties.itemId, "p1")
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddCartaddEvent.Builder(itemId: "p1")
            .customEventProperties(["qty": .int(2)])
            .build()
        if case .int(2)? = req.events[0].customEventProperties?["qty"] {} else {
            XCTFail()
        }
    }

    func testEmptyItemIdThrows() {
        XCTAssertThrowsError(try AddCartaddEvent.Builder(itemId: "").build())
    }

    func testTooLongItemIdThrows() {
        let long = String(repeating: "x", count: 501)
        XCTAssertThrowsError(try AddCartaddEvent.Builder(itemId: long).build())
    }

    func testItemId500CharsAllowed() throws {
        let id500 = String(repeating: "x", count: 500)
        let req = try AddCartaddEvent.Builder(itemId: id500).build()
        XCTAssertEqual(req.events[0].eventProperties.itemId?.count, 500)
    }

    func testEncodingMatchesContract() throws {
        let req = try AddCartaddEvent.Builder(itemId: "p").build()
        let data = try JSONEncoder().encode(req.events[0])
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["event_type"] as? String, "cartadd")
        let props = dict["event_properties"] as! [String: Any]
        XCTAssertEqual(props["item_id"] as? String, "p")
    }
}
