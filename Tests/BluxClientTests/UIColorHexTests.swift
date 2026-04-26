import XCTest
import UIKit
@testable import BluxClient

final class UIColorHexTests: XCTestCase {
    private func components(of color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = -1, g: CGFloat = -1, b: CGFloat = -1, a: CGFloat = -1
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    func testHexWithLeadingHash() {
        let color = UIColor(hex: "#FF0000")
        let (r, g, b, a) = components(of: color)
        XCTAssertEqual(r, 1.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testHexWithoutLeadingHash() {
        let color = UIColor(hex: "00FF00")
        let (r, g, b, a) = components(of: color)
        XCTAssertEqual(r, 0.0, accuracy: 0.001)
        XCTAssertEqual(g, 1.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testHexBlueChannel() {
        let color = UIColor(hex: "0000FF")
        let (r, g, b, _) = components(of: color)
        XCTAssertEqual(r, 0.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 1.0, accuracy: 0.001)
    }

    func testHexBlack() {
        let color = UIColor(hex: "#000000")
        let (r, g, b, _) = components(of: color)
        XCTAssertEqual(r, 0.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
    }

    func testHexWhite() {
        let color = UIColor(hex: "#FFFFFF")
        let (r, g, b, _) = components(of: color)
        XCTAssertEqual(r, 1.0, accuracy: 0.001)
        XCTAssertEqual(g, 1.0, accuracy: 0.001)
        XCTAssertEqual(b, 1.0, accuracy: 0.001)
    }

    func testHexLowercase() {
        let lower = UIColor(hex: "abcdef")
        let upper = UIColor(hex: "ABCDEF")
        let lc = components(of: lower)
        let uc = components(of: upper)
        XCTAssertEqual(lc.0, uc.0, accuracy: 0.001)
        XCTAssertEqual(lc.1, uc.1, accuracy: 0.001)
        XCTAssertEqual(lc.2, uc.2, accuracy: 0.001)
    }

    func testHexWithWhitespace() {
        let color = UIColor(hex: "  #FF8800  ")
        let (r, g, b, _) = components(of: color)
        XCTAssertEqual(r, 1.0, accuracy: 0.001)
        XCTAssertEqual(g, 136.0/255.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
    }

    func testInvalidHexFallsBackToBlack() {
        // Scanner가 hex로 파싱 실패하면 rgb=0이 되어 검정색이 됨
        let color = UIColor(hex: "ZZZZZZ")
        let (r, g, b, a) = components(of: color)
        XCTAssertEqual(r, 0.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testEmptyHexFallsBackToBlack() {
        let color = UIColor(hex: "")
        let (r, g, b, a) = components(of: color)
        XCTAssertEqual(r, 0.0, accuracy: 0.001)
        XCTAssertEqual(g, 0.0, accuracy: 0.001)
        XCTAssertEqual(b, 0.0, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }

    func testAlphaIsAlwaysOne() {
        let color = UIColor(hex: "#123456")
        let (_, _, _, a) = components(of: color)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }
}
