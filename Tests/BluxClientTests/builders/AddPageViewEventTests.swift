import XCTest
@testable import BluxClient

final class AddPageViewEventTests: XCTestCase {
    func testBuildProducesPageViewEvent() throws {
        let req = try AddPageViewEvent.Builder(page: "home").build()
        XCTAssertEqual(req.events[0].eventType, "page_view")
        XCTAssertEqual(req.events[0].eventProperties.page, "home")
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddPageViewEvent.Builder(page: "home")
            .customEventProperties(["scroll_depth": .double(0.75)])
            .build()
        if case .double(let v)? = req.events[0].customEventProperties?["scroll_depth"] {
            XCTAssertEqual(v, 0.75, accuracy: 0.001)
        } else {
            XCTFail()
        }
    }

    func testEmptyPageThrows() {
        XCTAssertThrowsError(try AddPageViewEvent.Builder(page: "").build())
    }

    func testTooLongPageThrows() {
        let long = String(repeating: "p", count: 501)
        XCTAssertThrowsError(try AddPageViewEvent.Builder(page: long).build())
    }
}
