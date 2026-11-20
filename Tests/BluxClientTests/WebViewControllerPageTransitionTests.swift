import UIKit
import XCTest
@testable import BluxClient

final class WebViewControllerPageTransitionTests: XCTestCase {
    func testPageTransitionCannotDismissAControllerWithAHostScreenAboveIt() {
        let controller = WebViewController(content: .htmlString(
            html: "<html></html>", baseURL: URL(string: "https://inapp.blux.ai")!
        ))
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        defer {
            controller.teardownWebView()
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertTrue(controller.canDismissOnPageTransition)
        let covering = UIViewController()
        controller.present(covering, animated: false)
        // SPM 러너는 foreground scene이 없으므로 dismiss 완료/재표시는 검증하지 않는다.
        // UIKit가 실제 설정한 presented 관계로 페이지 이동의 제외 조건만 검증한다.
        XCTAssertTrue(controller.presentedViewController === covering)
        XCTAssertFalse(controller.canDismissOnPageTransition)
    }
}
