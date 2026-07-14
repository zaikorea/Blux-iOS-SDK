import XCTest
@testable import BluxClient

final class WebViewControllerLeakTests: XCTestCase {
    // teardownWebView가 두 순환(script handler의 self 보유, 핸들러 클로저의 self 캡처)을
    // 끊는지만 보장한다. viewDidDisappear의 종료 판정은 수동 검증(Instruments) 대상.
    func testTeardownBreaksBothRetainCycles() {
        weak var weakVC: WebViewController?
        autoreleasepool {
            var vc: WebViewController? = WebViewController(
                content: .htmlString(
                    html: "<html></html>",
                    baseURL: URL(string: "https://blux.ai")!
                )
            )
            vc!.loadViewIfNeeded()
            let captured = vc! // InappService 핸들러의 캡처 재현
            vc!.addMessageHandler(for: "hide") { _ in _ = captured }

            vc!.teardownWebView()

            weakVC = vc
            vc = nil
        }
        XCTAssertNil(weakVC, "철거 후 WebViewController는 해제되어야 한다")
    }
}
