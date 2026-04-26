import XCTest
@testable import BluxClient

final class CustomValueTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Encoding

    func testEncodeString() throws {
        let value = CustomValue.string("hello")
        let data = try encoder.encode(value)
        XCTAssertEqual(String(data: data, encoding: .utf8), "\"hello\"")
    }

    func testEncodeBoolTrue() throws {
        let data = try encoder.encode(CustomValue.bool(true))
        XCTAssertEqual(String(data: data, encoding: .utf8), "true")
    }

    func testEncodeBoolFalse() throws {
        let data = try encoder.encode(CustomValue.bool(false))
        XCTAssertEqual(String(data: data, encoding: .utf8), "false")
    }

    func testEncodeInt() throws {
        let data = try encoder.encode(CustomValue.int(42))
        XCTAssertEqual(String(data: data, encoding: .utf8), "42")
    }

    func testEncodeNegativeInt() throws {
        let data = try encoder.encode(CustomValue.int(-7))
        XCTAssertEqual(String(data: data, encoding: .utf8), "-7")
    }

    func testEncodeDouble() throws {
        let data = try encoder.encode(CustomValue.double(3.5))
        XCTAssertEqual(String(data: data, encoding: .utf8), "3.5")
    }

    func testEncodeNull() throws {
        let data = try encoder.encode(CustomValue.null)
        XCTAssertEqual(String(data: data, encoding: .utf8), "null")
    }

    func testEncodeStringArray() throws {
        let data = try encoder.encode(CustomValue.stringArray(["a", "b"]))
        XCTAssertEqual(String(data: data, encoding: .utf8), "[\"a\",\"b\"]")
    }

    func testEncodeEmptyStringArray() throws {
        let data = try encoder.encode(CustomValue.stringArray([]))
        XCTAssertEqual(String(data: data, encoding: .utf8), "[]")
    }

    // MARK: - Decoding

    func testDecodeString() throws {
        let value = try decoder.decode(CustomValue.self, from: "\"hello\"".data(using: .utf8)!)
        guard case .string("hello") = value else {
            XCTFail("Expected .string(\"hello\"), got \(value)")
            return
        }
    }

    func testDecodeBool() throws {
        let value = try decoder.decode(CustomValue.self, from: "true".data(using: .utf8)!)
        guard case .bool(true) = value else {
            XCTFail("Expected .bool(true), got \(value)")
            return
        }
    }

    func testDecodeInt() throws {
        let value = try decoder.decode(CustomValue.self, from: "42".data(using: .utf8)!)
        guard case .int(42) = value else {
            XCTFail("Expected .int(42), got \(value)")
            return
        }
    }

    func testDecodeDouble() throws {
        // 정수형이 먼저 매칭되니, 명확히 double인 케이스
        let value = try decoder.decode(CustomValue.self, from: "1.5".data(using: .utf8)!)
        guard case .double(let d) = value else {
            XCTFail("Expected .double, got \(value)")
            return
        }
        XCTAssertEqual(d, 1.5, accuracy: 0.0001)
    }

    func testDecodeStringArray() throws {
        let value = try decoder.decode(CustomValue.self, from: "[\"a\",\"b\"]".data(using: .utf8)!)
        guard case .stringArray(let arr) = value else {
            XCTFail("Expected .stringArray, got \(value)")
            return
        }
        XCTAssertEqual(arr, ["a", "b"])
    }

    func testDecodeNull() throws {
        let value = try decoder.decode(CustomValue.self, from: "null".data(using: .utf8)!)
        guard case .null = value else {
            XCTFail("Expected .null, got \(value)")
            return
        }
    }

    func testDecodeUnsupportedTypeThrows() {
        // 객체 형태는 지원되지 않음
        XCTAssertThrowsError(try decoder.decode(CustomValue.self, from: "{}".data(using: .utf8)!))
    }

    func testDecodeMixedNumberArrayThrows() {
        // 숫자 배열은 stringArray가 아니라서 fail
        XCTAssertThrowsError(try decoder.decode(CustomValue.self, from: "[1,2,3]".data(using: .utf8)!))
    }

    // MARK: - Round-trip

    func testRoundTripAllVariants() throws {
        let cases: [CustomValue] = [
            .string("test"),
            .bool(true),
            .int(123),
            .double(2.71),
            .null,
            .stringArray(["x", "y", "z"])
        ]
        for original in cases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(CustomValue.self, from: data)
            // Compare by re-encoding (Equatable 미정의)
            let reData = try encoder.encode(decoded)
            XCTAssertEqual(data, reData, "Round-trip mismatch for \(original)")
        }
    }
}
