import XCTest
@testable import BluxClient

final class BannerWindowTests: XCTestCase {
    // notch 59pt + 홈 인디케이터 34pt 기준
    private let screen = CGRect(x: 0, y: 0, width: 393, height: 852)
    private let insets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)

    private func frame(_ options: [String: Any]) -> CGRect {
        BannerWindow.absoluteFrame(
            options: options,
            screenBounds: screen,
            safeAreaInsets: insets
        )
    }

    func testWidthAutoCalculatedFromLeftAndRight() {
        let f = frame(["height": 70, "bottom": 16, "left": 16, "right": 67])
        XCTAssertEqual(f.origin.x, 16)
        XCTAssertEqual(f.width, 393 - 16 - 67)
    }

    func testBottomRespectsSafeAreaInset() {
        let f = frame(["width": 200, "height": 70, "bottom": 16])
        XCTAssertEqual(f.maxY, 852 - 34 - 16)
    }

    func testTopRespectsSafeAreaInset() {
        let f = frame(["width": 200, "height": 60, "top": 20])
        XCTAssertEqual(f.origin.y, 59 + 20)
    }

    func testHeightAutoCalculatedFromTopAndBottom() {
        let f = frame(["width": 200, "top": 100, "bottom": 100])
        XCTAssertEqual(f.height, (852 - 59 - 34) - 100 - 100)
        XCTAssertEqual(f.origin.y, 59 + 100)
    }

    func testTopTakesPrecedenceWhenHeightGiven() {
        let f = frame(["width": 200, "height": 70, "top": 10, "bottom": 99])
        XCTAssertEqual(f.origin.y, 59 + 10)
        XCTAssertEqual(f.height, 70)
    }

    func testRightOnlyPositionsFromRightEdge() {
        let f = frame(["width": 320, "height": 60, "top": 20, "right": 20])
        XCTAssertEqual(f.maxX, 393 - 20)
    }

    func testCentersHorizontallyWithoutLeftRight() {
        let f = frame(["width": 200, "height": 64, "bottom": 80])
        XCTAssertEqual(f.midX, 393 / 2)
    }

    func testDefaultsToSafeAreaBounds() {
        let f = frame([:])
        XCTAssertEqual(f, CGRect(x: 0, y: 59, width: 393, height: 852 - 59 - 34))
    }

    func testSizeClampedToZeroWhenMarginsExceedScreen() {
        let f = frame(["left": 300, "right": 300, "height": 50, "bottom": 0])
        XCTAssertEqual(f.width, 0)
    }

    func testLandscapeInsetsShiftHorizontalFrame() {
        let f = BannerWindow.absoluteFrame(
            options: ["height": 70, "bottom": 16, "left": 16, "right": 67],
            screenBounds: CGRect(x: 0, y: 0, width: 852, height: 393),
            safeAreaInsets: UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59)
        )
        XCTAssertEqual(f.origin.x, 59 + 16)
        XCTAssertEqual(f.width, (852 - 59 - 59) - 16 - 67)
        XCTAssertEqual(f.maxY, 393 - 21 - 16)
    }

    // WKScriptMessage body의 숫자는 NSNumber(Double)로 들어올 수 있다.
    func testParsesDoubleValues() {
        let f = frame(["width": 320.5, "height": 60.0, "left": 16.5, "top": 0])
        XCTAssertEqual(f.width, 320.5)
        XCTAssertEqual(f.origin.x, 16.5)
    }
}
