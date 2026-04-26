import XCTest
@testable import BluxClient

final class EventRequestTests: XCTestCase {
    func testEmptyRequestHasNoEvents() {
        let req = EventRequest()
        XCTAssertEqual(req.events.count, 0)
        XCTAssertEqual(req.getPayload().count, 0)
    }

    func testAppendingEvents() {
        let req = EventRequest()
        req.events.append(Event(eventType: "a"))
        req.events.append(Event(eventType: "b"))
        XCTAssertEqual(req.getPayload().count, 2)
        XCTAssertEqual(req.getPayload()[0].eventType, "a")
        XCTAssertEqual(req.getPayload()[1].eventType, "b")
    }

    func testGetPayloadIgnoresIsTestFlag() {
        let req = EventRequest()
        req.events.append(Event(eventType: "x"))
        // isTest 파라미터는 현재 구현에서 사용되지 않음
        XCTAssertEqual(req.getPayload(isTest: true).count, 1)
        XCTAssertEqual(req.getPayload(isTest: false).count, 1)
    }
}
