import XCTest
@testable import BluxClient

final class AddProductDetailViewEventTests: XCTestCase {
    func testBuildProducesPDVEvent() throws {
        let req = try AddProductDetailViewEvent.Builder(itemId: "p1").build()
        XCTAssertEqual(req.events[0].eventType, "product_detail_view")
        XCTAssertEqual(req.events[0].eventProperties.itemId, "p1")
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddProductDetailViewEvent.Builder(itemId: "p1")
            .customEventProperties(["recommended": .bool(true)])
            .build()
        if case .bool(true)? = req.events[0].customEventProperties?["recommended"] {} else {
            XCTFail()
        }
    }

    func testEmptyItemIdThrows() {
        XCTAssertThrowsError(try AddProductDetailViewEvent.Builder(itemId: "").build())
    }
}
