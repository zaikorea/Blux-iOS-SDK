import XCTest
@testable import BluxClient

final class NSNumberClassifierTests: XCTestCase {
    // MARK: - Bool

    func testClassifyBoolTrue() {
        guard case let .bool(value)? = NSNumberClassifier.classify(true) else {
            XCTFail("Expected .bool")
            return
        }
        XCTAssertTrue(value)
    }

    func testClassifyBoolFalse() {
        guard case let .bool(value)? = NSNumberClassifier.classify(false) else {
            XCTFail("Expected .bool")
            return
        }
        XCTAssertFalse(value)
    }

    func testClassifyNSNumberFromBool() {
        guard case let .bool(value)? = NSNumberClassifier.classify(NSNumber(value: true)) else {
            XCTFail("Expected .bool")
            return
        }
        XCTAssertTrue(value)
    }

    // MARK: - Int

    func testClassifyInt() {
        guard case let .int(value)? = NSNumberClassifier.classify(42) else {
            XCTFail("Expected .int")
            return
        }
        XCTAssertEqual(value, 42)
    }

    func testClassifyNegativeInt() {
        guard case let .int(value)? = NSNumberClassifier.classify(-7) else {
            XCTFail("Expected .int")
            return
        }
        XCTAssertEqual(value, -7)
    }

    func testClassifyZeroInt() {
        guard case let .int(value)? = NSNumberClassifier.classify(0) else {
            XCTFail("Expected .int")
            return
        }
        XCTAssertEqual(value, 0)
    }

    func testClassifyLargeInt() {
        let big = Int.max
        guard case let .int(value)? = NSNumberClassifier.classify(big) else {
            XCTFail("Expected .int")
            return
        }
        XCTAssertEqual(value, big)
    }

    // MARK: - Double

    func testClassifyDouble() {
        guard case let .double(value)? = NSNumberClassifier.classify(3.14) else {
            XCTFail("Expected .double")
            return
        }
        XCTAssertEqual(value, 3.14, accuracy: 0.0001)
    }

    func testClassifyFloat() {
        let f: Float = 1.5
        guard case let .double(value)? = NSNumberClassifier.classify(f) else {
            XCTFail("Expected .double for Float, got: \(String(describing: NSNumberClassifier.classify(f)))")
            return
        }
        XCTAssertEqual(value, 1.5, accuracy: 0.0001)
    }

    func testClassifyZeroDouble() {
        guard case let .double(value)? = NSNumberClassifier.classify(0.0 as Double) else {
            XCTFail("Expected .double")
            return
        }
        XCTAssertEqual(value, 0.0)
    }

    // MARK: - Non-NSNumber

    func testClassifyStringReturnsNil() {
        XCTAssertNil(NSNumberClassifier.classify("hello"))
    }

    func testClassifyArrayReturnsNil() {
        XCTAssertNil(NSNumberClassifier.classify([1, 2, 3]))
    }

    func testClassifyDictReturnsNil() {
        XCTAssertNil(NSNumberClassifier.classify(["a": 1]))
    }

    func testClassifyNSNullReturnsNil() {
        XCTAssertNil(NSNumberClassifier.classify(NSNull()))
    }

    // MARK: - Bool vs Int discrimination (가장 중요한 엣지 케이스)

    func testBoolNotMisclassifiedAsInt() {
        // NSNumber 1 == true에 대해 .bool로 분류돼야 함
        let yesAsAny: Any = NSNumber(value: true)
        let noAsAny: Any = NSNumber(value: false)
        if case .int = NSNumberClassifier.classify(yesAsAny) {
            XCTFail("true must not be classified as int")
        }
        if case .int = NSNumberClassifier.classify(noAsAny) {
            XCTFail("false must not be classified as int")
        }
    }

    func testIntNotMisclassifiedAsBool() {
        if case .bool = NSNumberClassifier.classify(1) {
            XCTFail("1 (Int literal) must not be classified as bool")
        }
        if case .bool = NSNumberClassifier.classify(0) {
            XCTFail("0 (Int literal) must not be classified as bool")
        }
    }
}
