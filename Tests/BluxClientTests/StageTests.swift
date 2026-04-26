import XCTest
@testable import BluxClient

final class StageTests: XCTestCase {
    func testFromKnownLowercase() {
        XCTAssertEqual(Stage.from("local"), .local)
        XCTAssertEqual(Stage.from("dev"), .dev)
        XCTAssertEqual(Stage.from("stg"), .stg)
        XCTAssertEqual(Stage.from("prod"), .prod)
    }

    func testFromKnownUppercase() {
        XCTAssertEqual(Stage.from("LOCAL"), .local)
        XCTAssertEqual(Stage.from("DEV"), .dev)
        XCTAssertEqual(Stage.from("STG"), .stg)
        XCTAssertEqual(Stage.from("PROD"), .prod)
    }

    func testFromMixedCase() {
        XCTAssertEqual(Stage.from("Dev"), .dev)
        XCTAssertEqual(Stage.from("dEv"), .dev)
    }

    func testFromNilFallsBackToProd() {
        XCTAssertEqual(Stage.from(nil), .prod)
    }

    func testFromEmptyStringFallsBackToProd() {
        XCTAssertEqual(Stage.from(""), .prod)
    }

    func testFromUnknownValueFallsBackToProd() {
        XCTAssertEqual(Stage.from("staging"), .prod)
        XCTAssertEqual(Stage.from("production"), .prod)
        XCTAssertEqual(Stage.from("nonsense"), .prod)
    }

    func testApiBaseURL() {
        XCTAssertEqual(Stage.local.apiBaseURL, .local)
        XCTAssertEqual(Stage.dev.apiBaseURL, .dev)
        XCTAssertEqual(Stage.stg.apiBaseURL, .stg)
        XCTAssertEqual(Stage.prod.apiBaseURL, .prod)
    }

    func testAPIBaseURLValues() {
        XCTAssertEqual(HTTPClient.APIBaseURLByStage.local.rawValue, "http://localhost:3003/red/red")
        XCTAssertEqual(HTTPClient.APIBaseURLByStage.dev.rawValue, "https://api.blux.ai/dev")
        XCTAssertEqual(HTTPClient.APIBaseURLByStage.stg.rawValue, "https://api.blux.ai/stg")
        XCTAssertEqual(HTTPClient.APIBaseURLByStage.prod.rawValue, "https://api.blux.ai/prod")
    }

    func testAllCasesContainsAllStages() {
        XCTAssertEqual(Set(Stage.allCases), Set([.local, .dev, .stg, .prod]))
    }

    // MARK: - setStage / resetStage

    /// 빌드 시점 기본 스테이지가 prod이 아닐 때만 setStage가 동작.
    /// 테스트 환경에서는 BLUX_LOCAL/DEV/STG flag가 없으므로 default는 prod.
    /// 따라서 setStage는 false를 반환하고 current는 prod 유지.
    func testSetStageReturnsFalseWhenDefaultIsProd() {
        let result = Stage.setStage(.dev)
        XCTAssertFalse(result, "Default stage in test build is prod, so setStage should be no-op")
        XCTAssertEqual(Stage.current, .prod)
    }

    func testResetStageIsNoOpWhenDefaultIsProd() {
        // resetStage는 단순히 prod default일 때 early return; 크래시 없으면 통과
        Stage.resetStage()
        XCTAssertEqual(Stage.current, .prod)
    }

    func testStageSwitcherForwardsToStage() {
        StageSwitcher.setStage("dev")
        // default가 prod라 변경되지 않아야 함
        XCTAssertEqual(Stage.current, .prod)

        StageSwitcher.setStage("invalid-value")
        XCTAssertEqual(Stage.current, .prod)

        StageSwitcher.resetStage()
        XCTAssertEqual(Stage.current, .prod)
    }
}
