import XCTest
@testable import BluxClient

final class AddLikeEventTests: XCTestCase {
    func testBuildProducesLikeEvent() throws {
        let req = try AddLikeEvent.Builder(itemId: "p1").build()
        XCTAssertEqual(req.events[0].eventType, "like")
        XCTAssertEqual(req.events[0].eventProperties.itemId, "p1")
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddLikeEvent.Builder(itemId: "p1")
            .customEventProperties(["source": .string("feed")])
            .build()
        if case .string("feed")? = req.events[0].customEventProperties?["source"] {} else {
            XCTFail()
        }
    }

    func testEmptyItemIdThrows() {
        XCTAssertThrowsError(try AddLikeEvent.Builder(itemId: "").build())
    }

    func testEncodingShape() throws {
        let req = try AddLikeEvent.Builder(itemId: "abc").build()
        let data = try JSONEncoder().encode(req.events[0])
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["event_type"] as? String, "like")
    }
}
