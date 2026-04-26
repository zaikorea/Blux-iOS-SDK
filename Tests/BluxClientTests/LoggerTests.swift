import XCTest
@testable import BluxClient

final class LoggerTests: XCTestCase {
    func testLogLevelRawValues() {
        XCTAssertEqual(LogLevel.none.rawValue, 0)
        XCTAssertEqual(LogLevel.error.rawValue, 1)
        XCTAssertEqual(LogLevel.verbose.rawValue, 5)
    }

    func testLogLevelDescription() {
        XCTAssertEqual(LogLevel.none.description, "none")
        XCTAssertEqual(LogLevel.error.description, "error")
        XCTAssertEqual(LogLevel.verbose.description, "verbose")
    }

    func testLogLevelOrdering() {
        XCTAssertLessThan(LogLevel.none.rawValue, LogLevel.error.rawValue)
        XCTAssertLessThan(LogLevel.error.rawValue, LogLevel.verbose.rawValue)
    }

    func testLoggerEmitsWithoutCrashing() {
        // Logger는 os_log 호출만 하고 반환값이 없으니 크래시만 없으면 통과
        Logger.error("test error")
        Logger.verbose("test verbose")
    }

    func testLoggerRespectsLogLevelThresholdAtNone() {
        let saved = SdkConfig.logLevel
        defer { SdkConfig.logLevel = saved }

        SdkConfig.logLevel = .none
        // 둘 다 호출되지만 출력만 안 됨; 크래시 검증
        Logger.error("should be suppressed")
        Logger.verbose("should be suppressed")
    }

    func testLoggerRespectsLogLevelThresholdAtError() {
        let saved = SdkConfig.logLevel
        defer { SdkConfig.logLevel = saved }

        SdkConfig.logLevel = .error
        Logger.error("emitted")
        Logger.verbose("suppressed")
    }
}
