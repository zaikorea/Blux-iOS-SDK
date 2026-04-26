import XCTest
@testable import BluxClient

final class NotificationUrlOpenOptionsTests: XCTestCase {
    func testDefaultIsInternalWebView() {
        let options = NotificationUrlOpenOptions()
        XCTAssertEqual(options.httpUrlOpenTarget, .internalWebView)
    }

    func testInitWithExternalBrowser() {
        let options = NotificationUrlOpenOptions(httpUrlOpenTarget: .externalBrowser)
        XCTAssertEqual(options.httpUrlOpenTarget, .externalBrowser)
    }

    func testInitWithNone() {
        let options = NotificationUrlOpenOptions(httpUrlOpenTarget: .none)
        XCTAssertEqual(options.httpUrlOpenTarget, .none)
    }

    func testHttpUrlOpenTargetRawValues() {
        XCTAssertEqual(HttpUrlOpenTarget.internalWebView.rawValue, 0)
        XCTAssertEqual(HttpUrlOpenTarget.externalBrowser.rawValue, 1)
        XCTAssertEqual(HttpUrlOpenTarget.none.rawValue, 2)
    }

    func testHttpUrlOpenTargetRawInit() {
        // .none이 Optional<HttpUrlOpenTarget>.none과 충돌하므로 rawValue로 비교
        XCTAssertEqual(HttpUrlOpenTarget(rawValue: 0)?.rawValue, HttpUrlOpenTarget.internalWebView.rawValue)
        XCTAssertEqual(HttpUrlOpenTarget(rawValue: 1)?.rawValue, HttpUrlOpenTarget.externalBrowser.rawValue)
        XCTAssertEqual(HttpUrlOpenTarget(rawValue: 2)?.rawValue, HttpUrlOpenTarget.none.rawValue)
        XCTAssertNil(HttpUrlOpenTarget(rawValue: 99))
        XCTAssertNil(HttpUrlOpenTarget(rawValue: -1))
    }
}
