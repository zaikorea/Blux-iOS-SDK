import XCTest
@testable import BluxClient

final class WebViewControllerHostDisplayTests: XCTestCase {
    func testHidesBluxLandingHosts() {
        XCTAssertTrue(WebViewController.shouldHideHost("landing.blux.ai"))
        XCTAssertTrue(WebViewController.shouldHideHost("dev.landing.blux.ai"))
        XCTAssertTrue(WebViewController.shouldHideHost("LANDING.BLUX.AI"))
    }

    func testShowsOtherHostsIncludingLookalikes() {
        XCTAssertFalse(WebViewController.shouldHideHost("example.com"))
        XCTAssertFalse(WebViewController.shouldHideHost("attacker-landing.blux.ai"))
        XCTAssertFalse(WebViewController.shouldHideHost("landing.blux.ai.attacker.com"))
        XCTAssertFalse(WebViewController.shouldHideHost(""))
    }
}
