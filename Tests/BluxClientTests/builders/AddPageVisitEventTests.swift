import XCTest
@testable import BluxClient

final class AddPageVisitEventTests: XCTestCase {
    func testBuildProducesPageVisitEvent() throws {
        let req = try AddPageVisitEvent.Builder().build()
        XCTAssertEqual(req.events[0].eventType, "page_visit")
    }

    func testBuildWithCustomEventProperties() throws {
        let req = try AddPageVisitEvent.Builder()
            .customEventProperties(["referrer": .string("google")])
            .build()
        if case .string("google")? = req.events[0].customEventProperties?["referrer"] {} else {
            XCTFail()
        }
    }

    func testNoSetters() throws {
        let req = try AddPageVisitEvent.Builder().build()
        XCTAssertNil(req.events[0].eventProperties.itemId)
        XCTAssertNil(req.events[0].eventProperties.page)
    }
}
