import XCTest
@testable import BluxClient

final class CustomEventValueTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Encoding

    func testEncodeString() throws {
        let data = try encoder.encode(CustomEventValue.string("hello"))
        XCTAssertEqual(String(data: data, encoding: .utf8), "\"hello\"")
    }

    func testEncodeBool() throws {
        let data = try encoder.encode(CustomEventValue.bool(false))
        XCTAssertEqual(String(data: data, encoding: .utf8), "false")
    }

    func testEncodeInt() throws {
        let data = try encoder.encode(CustomEventValue.int(7))
        XCTAssertEqual(String(data: data, encoding: .utf8), "7")
    }

    func testEncodeDouble() throws {
        let data = try encoder.encode(CustomEventValue.double(0.5))
        XCTAssertEqual(String(data: data, encoding: .utf8), "0.5")
    }

    func testEncodeStringArray() throws {
        let data = try encoder.encode(CustomEventValue.stringArray(["x"]))
        XCTAssertEqual(String(data: data, encoding: .utf8), "[\"x\"]")
    }

    // MARK: - Decoding ordering: Bool > Int > Double > String > StringArray

    func testDecodeBoolBeforeInt() throws {
        // 불리언 먼저 시도되므로 true/false는 .bool로
        let value = try decoder.decode(CustomEventValue.self, from: "true".data(using: .utf8)!)
        guard case .bool(true) = value else {
            XCTFail("Expected .bool(true), got \(value)")
            return
        }
    }

    func testDecodeIntegerLiteralAsInt() throws {
        let value = try decoder.decode(CustomEventValue.self, from: "10".data(using: .utf8)!)
        guard case .int(10) = value else {
            XCTFail("Expected .int(10), got \(value)")
            return
        }
    }

    func testDecodeFractionalAsDouble() throws {
        let value = try decoder.decode(CustomEventValue.self, from: "1.25".data(using: .utf8)!)
        guard case .double(let d) = value else {
            XCTFail("Expected .double, got \(value)")
            return
        }
        XCTAssertEqual(d, 1.25, accuracy: 0.0001)
    }

    func testDecodeString() throws {
        let value = try decoder.decode(CustomEventValue.self, from: "\"abc\"".data(using: .utf8)!)
        guard case .string("abc") = value else {
            XCTFail("Expected .string(\"abc\"), got \(value)")
            return
        }
    }

    func testDecodeStringArray() throws {
        let value = try decoder.decode(CustomEventValue.self, from: "[\"a\",\"b\"]".data(using: .utf8)!)
        guard case .stringArray(let arr) = value else {
            XCTFail("Expected .stringArray, got \(value)")
            return
        }
        XCTAssertEqual(arr, ["a", "b"])
    }

    func testDecodeUnsupportedThrows() {
        // 객체는 지원 안 됨 (CustomValue와 다르게 null도 지원 안 함)
        XCTAssertThrowsError(try decoder.decode(CustomEventValue.self, from: "{}".data(using: .utf8)!))
    }

    func testDecodeNullThrows() {
        // CustomEventValue는 null 케이스가 없음
        XCTAssertThrowsError(try decoder.decode(CustomEventValue.self, from: "null".data(using: .utf8)!))
    }

    // MARK: - fromAny

    func testFromAnyNilReturnsNil() {
        XCTAssertNil(CustomEventValue.fromAny(nil))
    }

    func testFromAnyBool() {
        guard case .bool(true)? = CustomEventValue.fromAny(true) else {
            XCTFail("Expected .bool(true)")
            return
        }
    }

    func testFromAnyInt() {
        guard case .int(42)? = CustomEventValue.fromAny(42) else {
            XCTFail("Expected .int(42)")
            return
        }
    }

    func testFromAnyDouble() {
        guard case .double(let d)? = CustomEventValue.fromAny(3.14) else {
            XCTFail("Expected .double")
            return
        }
        XCTAssertEqual(d, 3.14, accuracy: 0.0001)
    }

    func testFromAnyString() {
        guard case .string("hello")? = CustomEventValue.fromAny("hello") else {
            XCTFail("Expected .string")
            return
        }
    }

    func testFromAnyStringArray() {
        guard case .stringArray(let arr)? = CustomEventValue.fromAny(["a", "b"]) else {
            XCTFail("Expected .stringArray")
            return
        }
        XCTAssertEqual(arr, ["a", "b"])
    }

    // NSNumber로 들어오는 true가 .int(1)로 분류되면 서버에 boolean이 0/1로 전달됨.
    func testFromAnyBoolNSNumberStaysBool() {
        guard case .bool(true)? = CustomEventValue.fromAny(NSNumber(value: true)) else {
            XCTFail("NSNumber(true) must convert to .bool(true)")
            return
        }
    }

    func testFromAnyTrueLiteralIsBool() {
        guard case .bool(true)? = CustomEventValue.fromAny(true) else {
            XCTFail("true literal must convert to .bool(true)")
            return
        }
    }

    func testFromAnyIntLiteralStaysInt() {
        if case .bool = CustomEventValue.fromAny(1) {
            XCTFail("1 (Int literal) must NOT convert to .bool")
        }
    }

    func testFromAnyUnsupportedReturnsNil() {
        XCTAssertNil(CustomEventValue.fromAny([1, 2, 3]))
        XCTAssertNil(CustomEventValue.fromAny(["key": "value"]))
        XCTAssertNil(CustomEventValue.fromAny(NSObject()))
    }

    // MARK: - dictionaryFromAny

    func testDictionaryFromAnyConvertsKnownTypes() {
        let input: [String: Any] = [
            "name": "Alice",
            "age": 30,
            "score": 99.5,
            "active": true,
            "tags": ["a", "b"]
        ]
        let result = CustomEventValue.dictionaryFromAny(input)

        XCTAssertEqual(result.count, 5)
        if case .string("Alice")? = result["name"] {} else { XCTFail("name wrong") }
        if case .int(30)? = result["age"] {} else { XCTFail("age wrong") }
        if case .double(let s)? = result["score"] {
            XCTAssertEqual(s, 99.5, accuracy: 0.0001)
        } else {
            XCTFail("score wrong")
        }
        if case .bool(true)? = result["active"] {} else { XCTFail("active wrong") }
        if case .stringArray(let t)? = result["tags"] {
            XCTAssertEqual(t, ["a", "b"])
        } else {
            XCTFail("tags wrong")
        }
    }

    func testDictionaryFromAnyDropsUnsupportedTypes() {
        let input: [String: Any] = [
            "good": "value",
            "bad": NSObject(),
            "alsoBad": [1, 2]
        ]
        let result = CustomEventValue.dictionaryFromAny(input)

        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["good"])
        XCTAssertNil(result["bad"])
        XCTAssertNil(result["alsoBad"])
    }

    func testDictionaryFromAnyEmptyInputReturnsEmpty() {
        XCTAssertTrue(CustomEventValue.dictionaryFromAny([:]).isEmpty)
    }
}
