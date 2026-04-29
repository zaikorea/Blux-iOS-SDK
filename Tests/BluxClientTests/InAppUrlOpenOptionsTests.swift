import XCTest
@testable import BluxClient

final class InAppUrlOpenOptionsTests: XCTestCase {
    func testDefaultIsInternalWebView() {
        let options = InAppUrlOpenOptions()
        XCTAssertEqual(options.httpUrlOpenTarget, .internalWebView)
    }

    func testInitWithExternalBrowser() {
        let options = InAppUrlOpenOptions(httpUrlOpenTarget: .externalBrowser)
        XCTAssertEqual(options.httpUrlOpenTarget, .externalBrowser)
    }

    func testInitWithNone() {
        let options = InAppUrlOpenOptions(httpUrlOpenTarget: .none)
        XCTAssertEqual(options.httpUrlOpenTarget, .none)
    }
}
