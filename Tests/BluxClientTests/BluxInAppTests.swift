import XCTest
@testable import BluxClient

final class BluxInAppTests: XCTestCase {
    func testHoldsIdAndUrl() {
        let event = BluxInApp(id: "nid_1", url: "https://example.com/path")
        XCTAssertEqual(event.id, "nid_1")
        XCTAssertEqual(event.url, "https://example.com/path")
    }

    func testUrlCanBeNil() {
        let event = BluxInApp(id: "nid_2", url: nil)
        XCTAssertEqual(event.id, "nid_2")
        XCTAssertNil(event.url)
    }

    func testEmptyUrlIsNormalizedToNil() {
        let event = BluxInApp(id: "nid_3", url: "")
        XCTAssertNil(event.url, "Empty string url should normalize to nil (mirror of BluxNotification)")
    }
}
