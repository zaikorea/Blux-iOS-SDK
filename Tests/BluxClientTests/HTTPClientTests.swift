import XCTest
@testable import BluxClient

/// URLSession.shared를 직접 사용하므로 정상 경로 mocking은 어렵다.
/// 검증 가능한 경로:
/// - clientId가 nil이면 invalidRequest 에러로 즉시 completion
/// - HTTPError 케이스 식별
/// - setStage가 base URL을 변경
final class HTTPClientTests: XCTestCase {
    private var guardian: SdkStateGuard!

    override func setUp() {
        super.setUp()
        guardian = SdkStateGuard()
        guardian.clear()
    }

    override func tearDown() {
        guardian.restore()
        guardian = nil
        super.tearDown()
    }

    func testSharedIsSingleton() {
        XCTAssertTrue(HTTPClient.shared === HTTPClient.shared)
    }

    // MARK: - invalidRequest 경로 (clientId 없음)

    func testGetReturnsInvalidRequestWhenNoClientId() {
        let exp = expectation(description: "completion called")
        var receivedError: Error?

        HTTPClient.shared.get(path: "/x") { (_: EmptyResponse?, error) in
            receivedError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        assertInvalidRequest(receivedError)
    }

    func testPostReturnsInvalidRequestWhenNoClientId() {
        let exp = expectation(description: "completion called")
        var receivedError: Error?

        HTTPClient.shared.post(path: "/x", body: EmptyResponse()) { (_: EmptyResponse?, error) in
            receivedError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        assertInvalidRequest(receivedError)
    }

    func testPutReturnsInvalidRequestWhenNoClientId() {
        let exp = expectation(description: "completion called")
        var receivedError: Error?

        HTTPClient.shared.put(path: "/x", body: EmptyResponse()) { (_: EmptyResponse?, error) in
            receivedError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        assertInvalidRequest(receivedError)
    }

    func testPatchReturnsInvalidRequestWhenNoClientId() {
        let exp = expectation(description: "completion called")
        var receivedError: Error?

        HTTPClient.shared.patch(path: "/x", body: EmptyResponse()) { (_: EmptyResponse?, error) in
            receivedError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        assertInvalidRequest(receivedError)
    }

    private func assertInvalidRequest(_ error: Error?, file: StaticString = #file, line: UInt = #line) {
        guard let httpError = error as? HTTPClient.HTTPError else {
            XCTFail("Expected HTTPError, got \(String(describing: error))", file: file, line: line)
            return
        }
        if case .invalidRequest = httpError {
            return
        }
        XCTFail("Expected .invalidRequest, got \(httpError)", file: file, line: line)
    }

    // MARK: - HTTPError 케이스

    func testHTTPErrorServerSideErrorHoldsStatusCode() {
        let error = HTTPClient.HTTPError.serverSideError(503)
        if case let .serverSideError(code) = error {
            XCTAssertEqual(code, 503)
        } else {
            XCTFail()
        }
    }

    func testHTTPErrorTransportErrorWrapsUnderlying() {
        struct UnderlyingError: Error {}
        let error = HTTPClient.HTTPError.transportError(UnderlyingError())
        if case .transportError = error {
            // OK
        } else {
            XCTFail()
        }
    }

    // MARK: - setStage

    func testSetStageDoesNotCrash() {
        // setStage는 단순 baseURL 교체. private API라 외부에서 base URL을 직접 검증할 수 없으니
        // 호출 자체가 안전한지만 확인.
        HTTPClient.shared.setStage(.local)
        HTTPClient.shared.setStage(.dev)
        HTTPClient.shared.setStage(.stg)
        HTTPClient.shared.setStage(.prod)
    }

    // MARK: - EmptyResponse

    func testEmptyResponseEncodesToEmptyJSON() throws {
        let data = try JSONEncoder().encode(EmptyResponse())
        XCTAssertEqual(String(data: data, encoding: .utf8), "{}")
    }

    func testEmptyResponseDecodesFromEmptyJSON() throws {
        _ = try JSONDecoder().decode(EmptyResponse.self, from: "{}".data(using: .utf8)!)
    }
}
