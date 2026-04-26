import XCTest
@testable import BluxClient

final class ValidatorTests: XCTestCase {
    // MARK: - validateString (non-optional)

    func testValidateString_ReturnsValueWhenWithinRange() throws {
        let value = try Validator.validateString("hello", min: 1, max: 10, varName: "name")
        XCTAssertEqual(value, "hello")
    }

    func testValidateString_ReturnsValueAtMinBoundary() throws {
        let value = try Validator.validateString("a", min: 1, max: 10, varName: "name")
        XCTAssertEqual(value, "a")
    }

    func testValidateString_ReturnsValueAtMaxBoundary() throws {
        let value = try Validator.validateString("abcdefghij", min: 1, max: 10, varName: "name")
        XCTAssertEqual(value.count, 10)
    }

    func testValidateString_ThrowsWhenShorterThanMin() {
        XCTAssertThrowsError(try Validator.validateString("", min: 1, max: 10, varName: "name")) { error in
            guard case let BluxError.LengthOutOfRangeBetween(name, _, _) = error else {
                XCTFail("Expected LengthOutOfRangeBetween, got \(error)")
                return
            }
            XCTAssertEqual(name, "name")
        }
    }

    func testValidateString_ThrowsWhenLongerThanMax() {
        XCTAssertThrowsError(try Validator.validateString("abcdefghijk", min: 1, max: 10, varName: "name")) { error in
            guard case BluxError.LengthOutOfRangeBetween = error else {
                XCTFail("Expected LengthOutOfRangeBetween, got \(error)")
                return
            }
        }
    }

    func testValidateString_NoMaxOnlyChecksMin() throws {
        let value = try Validator.validateString("very long string with no upper bound applied", min: 1, varName: "page")
        XCTAssertFalse(value.isEmpty)
    }

    func testValidateString_NoMaxThrowsLengthOutOfRangeGeWhenShort() {
        XCTAssertThrowsError(try Validator.validateString("", min: 5, varName: "page")) { error in
            guard case BluxError.LengthOutOfRangeGe = error else {
                XCTFail("Expected LengthOutOfRangeGe, got \(error)")
                return
            }
        }
    }

    func testValidateString_HandlesUnicodeLength() throws {
        // 한글 5글자 (Character count 기준)
        let value = try Validator.validateString("안녕하세요", min: 5, max: 5, varName: "korean")
        XCTAssertEqual(value, "안녕하세요")
    }

    func testValidateString_RejectsBytesBeyondCharCount() {
        // emoji는 1글자로 카운트되어야 함
        XCTAssertThrowsError(try Validator.validateString("🎉🎉🎉", min: 4, max: 100, varName: "emoji"))
    }

    // MARK: - validateString (optional)

    func testValidateStringOptional_NilReturnsNil() throws {
        let value = try Validator.validateString(nil, min: 1, max: 10, varName: "name")
        XCTAssertNil(value)
    }

    func testValidateStringOptional_ValidValueReturnsValue() throws {
        let value = try Validator.validateString(Optional("hello"), min: 1, max: 10, varName: "name")
        XCTAssertEqual(value, "hello")
    }

    func testValidateStringOptional_ThrowsForOutOfRange() {
        XCTAssertThrowsError(try Validator.validateString(Optional(""), min: 1, max: 10, varName: "name"))
    }

    // MARK: - validateNumber

    func testValidateNumber_WithinRangeReturnsValue() throws {
        let value = try Validator.validateNumber(5.0, min: 0.0, max: 10.0, varName: "price")
        XCTAssertEqual(value, 5.0)
    }

    func testValidateNumber_AtMinBoundary() throws {
        let value = try Validator.validateNumber(0.0, min: 0.0, max: 10.0, varName: "price")
        XCTAssertEqual(value, 0.0)
    }

    func testValidateNumber_AtMaxBoundary() throws {
        let value = try Validator.validateNumber(10.0, min: 0.0, max: 10.0, varName: "price")
        XCTAssertEqual(value, 10.0)
    }

    func testValidateNumber_ThrowsWhenBelowMin() {
        XCTAssertThrowsError(try Validator.validateNumber(-1.0, min: 0.0, max: 10.0, varName: "price")) { error in
            guard case BluxError.ValueOutOfRangeBetween = error else {
                XCTFail("Expected ValueOutOfRangeBetween, got \(error)")
                return
            }
        }
    }

    func testValidateNumber_ThrowsWhenAboveMax() {
        XCTAssertThrowsError(try Validator.validateNumber(11.0, min: 0.0, max: 10.0, varName: "price")) { error in
            guard case BluxError.ValueOutOfRangeBetween = error else {
                XCTFail("Expected ValueOutOfRangeBetween, got \(error)")
                return
            }
        }
    }

    func testValidateNumber_NoMaxOnlyChecksMin() throws {
        let value = try Validator.validateNumber(99999.99, min: 0.0, varName: "price")
        XCTAssertEqual(value, 99999.99)
    }

    func testValidateNumber_NoMaxThrowsValueOutOfRangeGe() {
        XCTAssertThrowsError(try Validator.validateNumber(-0.01, min: 0.0, varName: "price")) { error in
            guard case BluxError.ValueOutOfRangeGe = error else {
                XCTFail("Expected ValueOutOfRangeGe, got \(error)")
                return
            }
        }
    }

    func testValidateNumber_GenericIntType() throws {
        let value = try Validator.validateNumber(42, min: 0, max: 100, varName: "age")
        XCTAssertEqual(value, 42)
    }
}
