import XCTest
@testable import BluxClient

@available(iOSApplicationExtension, unavailable)
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

    func testHidesNavigationBarOnLandingHost() {
        let chrome = presentedChrome(for: "https://landing.blux.ai/6943a0331d73435eac12aef6")
        XCTAssertTrue(chrome.barHidden)
        XCTAssertEqual(chrome.title, "")
    }

    func testKeepsNavigationBarOnOtherHost() {
        let chrome = presentedChrome(for: "https://attacker-landing.blux.ai/promo")
        XCTAssertFalse(chrome.barHidden)
        XCTAssertEqual(chrome.title, "attacker-landing.blux.ai")
    }

    /// 로드 완료 전에도 최초 host만으로 바 표시가 정해지는지 확인한다.
    private func presentedChrome(for urlString: String) -> (barHidden: Bool, title: String?) {
        let controller = WebViewController(content: .url(URL(string: urlString)!))
        let navigation = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 700))
        window.rootViewController = navigation
        window.makeKeyAndVisible()

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        return (navigation.isNavigationBarHidden, controller.navigationItem.title)
    }
}
