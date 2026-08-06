import WebKit
import XCTest
@testable import BluxClient

@available(iOSApplicationExtension, unavailable)
final class WebViewControllerHostDisplayTests: XCTestCase {
    private let landing = URL(string: "https://landing.blux.ai/6943a0331d73435eac12aef6")!
    private let external = URL(string: "https://example.com/promo")!

    // MARK: - origin 판정

    func testAcceptsBluxLandingOrigins() {
        XCTAssertTrue(WebViewController.isBluxLanding(landing))
        XCTAssertTrue(WebViewController.isBluxLanding(URL(string: "https://dev.landing.blux.ai/x")!))
        XCTAssertTrue(WebViewController.isBluxLanding(URL(string: "https://LANDING.BLUX.AI/x")!))
        XCTAssertTrue(WebViewController.isBluxLanding(URL(string: "https://landing.blux.ai:443/x")!))
    }

    func testRejectsLookalikeHosts() {
        XCTAssertFalse(WebViewController.isBluxLanding(external))
        XCTAssertFalse(WebViewController.isBluxLanding(URL(string: "https://attacker-landing.blux.ai/x")!))
        XCTAssertFalse(WebViewController.isBluxLanding(URL(string: "https://landing.blux.ai.attacker.com/x")!))
        XCTAssertFalse(WebViewController.isBluxLanding(nil))
    }

    /// host가 같아도 scheme·port가 다르면 같은 origin이 아니다.
    func testRejectsNonHttpsOrigins() {
        XCTAssertFalse(WebViewController.isBluxLanding(URL(string: "http://landing.blux.ai/x")!))
        XCTAssertFalse(WebViewController.isBluxLanding(URL(string: "https://landing.blux.ai:8443/x")!))
    }

    // MARK: - navigation 상태 전이

    func testHidesBarOnLandingBeforeLoad() {
        let (controller, navigation) = present(contentURL: landing)
        XCTAssertTrue(navigation.isNavigationBarHidden)
        XCTAssertEqual(controller.navigationItem.title, "")
    }

    func testKeepsBarOnExternalHost() {
        let (controller, navigation) = present(contentURL: external)
        XCTAssertFalse(navigation.isNavigationBarHidden)
        XCTAssertEqual(controller.navigationItem.title, "example.com")
    }

    /// 랜딩에서 외부 사이트로 이동한 문서가 표시되기 시작하면 바가 복구돼야 한다.
    func testRestoresBarWhenExternalDocumentCommits() {
        let (controller, navigation) = present(contentURL: landing)
        XCTAssertTrue(navigation.isNavigationBarHidden)

        controller.webView(webView(showing: external), didCommit: nil)

        XCTAssertFalse(navigation.isNavigationBarHidden)
        XCTAssertEqual(controller.navigationItem.title, "example.com")
    }

    /// 외부 사이트에서 랜딩으로 돌아온 문서가 표시되기 시작하면 다시 감춰야 한다.
    func testHidesBarWhenLandingDocumentCommits() {
        let (controller, navigation) = present(contentURL: external)
        XCTAssertFalse(navigation.isNavigationBarHidden)

        controller.webView(webView(showing: landing), didCommit: nil)

        XCTAssertTrue(navigation.isNavigationBarHidden)
        XCTAssertEqual(controller.navigationItem.title, "")
    }

    /// 이동이 실패하면 화면에 남아 있는 문서 기준으로 되돌아가야 한다.
    func testFallsBackToVisibleDocumentWhenNavigationFails() {
        let (_, navigation) = present(contentURL: landing)
        let stillShowingExternal = webView(showing: external)

        navigation.viewControllers.compactMap { $0 as? WebViewController }.forEach {
            $0.webView(
                stillShowingExternal, didFailProvisionalNavigation: nil,
                withError: URLError(.notConnectedToInternet)
            )
        }

        XCTAssertFalse(navigation.isNavigationBarHidden)
    }

    // MARK: - helpers

    private func present(contentURL: URL) -> (WebViewController, UINavigationController) {
        let controller = WebViewController(content: .url(contentURL))
        let navigation = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 700))
        window.rootViewController = navigation
        window.makeKeyAndVisible()

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        return (controller, navigation)
    }

    /// 델리게이트에 넘길 웹뷰. 네트워크 없이 `url`만 원하는 값으로 채운다.
    private func webView(showing url: URL) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString("<html><body></body></html>", baseURL: url)
        let deadline = Date().addingTimeInterval(3)
        while webView.url == nil, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertEqual(webView.url, url)
        return webView
    }
}
