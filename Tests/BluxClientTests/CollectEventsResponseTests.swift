import XCTest
@testable import BluxClient

final class CollectEventsResponseTests: XCTestCase {
    private let decoder = JSONDecoder()

    func testDecodeMinimalResponse() throws {
        let json = "{}".data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertNil(response.nextPollDelayMs)
        XCTAssertNil(response.inapp)
    }

    func testDecodeNextPollDelayOnly() throws {
        let json = "{\"nextPollDelayMs\":3000}".data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertEqual(response.nextPollDelayMs, 3000)
        XCTAssertNil(response.inapp)
    }

    func testDecodeInappOnly() throws {
        let json = """
        {
          "inapp": {
            "notificationId": "n1",
            "htmlString": "<html></html>",
            "inappId": "i1",
            "baseUrl": "https://cdn.blux.ai"
          }
        }
        """.data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertNil(response.nextPollDelayMs)
        XCTAssertNotNil(response.inapp)
        XCTAssertEqual(response.inapp?.notificationId, "n1")
        XCTAssertEqual(response.inapp?.htmlString, "<html></html>")
        XCTAssertEqual(response.inapp?.inappId, "i1")
        XCTAssertEqual(response.inapp?.baseUrl, "https://cdn.blux.ai")
    }

    func testDecodeFullResponse() throws {
        let json = """
        {
          "nextPollDelayMs": 5000,
          "inapp": {
            "notificationId": "n",
            "htmlString": "h",
            "inappId": "i",
            "baseUrl": "b"
          }
        }
        """.data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertEqual(response.nextPollDelayMs, 5000)
        XCTAssertEqual(response.inapp?.notificationId, "n")
    }

    func testDecodeMissingInappFieldThrows() {
        // inapp이 있다면 모든 필드가 필수
        let json = """
        { "inapp": { "notificationId": "n" } }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(CollectEventsResponse.self, from: json))
    }

    func testDecodeNegativeDelayPassesThrough() throws {
        // 서버가 음수 보내도 디코딩 자체는 통과 (검증은 EventService에서 max(_, 3000) 적용)
        let json = "{\"nextPollDelayMs\":-1000}".data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertEqual(response.nextPollDelayMs, -1000)
    }

    // 0초가 그대로 통과되어도 EventService 내부에서 max(_, 3000)으로 정규화된다.
    func testDecodeZeroDelayPassesThrough() throws {
        let json = "{\"nextPollDelayMs\":0}".data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertEqual(response.nextPollDelayMs, 0)
    }

    func testDecodeIgnoresExtraFields() throws {
        let json = "{\"nextPollDelayMs\":1000,\"unknown\":\"value\"}".data(using: .utf8)!
        let response = try decoder.decode(CollectEventsResponse.self, from: json)
        XCTAssertEqual(response.nextPollDelayMs, 1000)
    }
}
