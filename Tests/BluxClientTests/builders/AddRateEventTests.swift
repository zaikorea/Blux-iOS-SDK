import XCTest
@testable import BluxClient

final class AddRateEventTests: XCTestCase {
    func testBuildProducesRateEvent() throws {
        let req = try AddRateEvent.Builder(itemId: "p1", rating: 5.0).build()
        XCTAssertEqual(req.events[0].eventType, "rate")
        XCTAssertEqual(req.events[0].eventProperties.itemId, "p1")
        XCTAssertEqual(req.events[0].eventProperties.rating, 5.0)
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddRateEvent.Builder(itemId: "p1", rating: 4.5)
            .customEventProperties(["category": .string("good")])
            .build()
        if case .string("good")? = req.events[0].customEventProperties?["category"] {} else {
            XCTFail()
        }
    }

    func testEmptyItemIdThrows() {
        XCTAssertThrowsError(try AddRateEvent.Builder(itemId: "", rating: 4.0).build())
    }

    func testRatingZeroAllowed() throws {
        let req = try AddRateEvent.Builder(itemId: "p", rating: 0).build()
        XCTAssertEqual(req.events[0].eventProperties.rating, 0)
    }

    func testRatingNegativeAllowed() throws {
        // setRating은 검증 없음 (Validator 호출 안 함)
        let req = try AddRateEvent.Builder(itemId: "p", rating: -1).build()
        XCTAssertEqual(req.events[0].eventProperties.rating, -1)
    }

    func testRatingFractional() throws {
        let req = try AddRateEvent.Builder(itemId: "p", rating: 3.7).build()
        XCTAssertEqual(req.events[0].eventProperties.rating, 3.7)
    }
}
