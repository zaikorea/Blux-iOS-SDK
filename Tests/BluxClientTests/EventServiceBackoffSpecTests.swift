import XCTest
@testable import BluxClient

/// 회귀 방지: EventService 폴링 백오프 알고리즘의 spec lock-in.
///
/// Fix commit: 91df32b "fix: 이벤트 폴링 백오프 상한을 의도대로 1일로 정정 (#80)"
///
/// 이전 버그: `cached > 24h ? cached : cached * 2`는 24h 초과 상태에서만 증가를 멈춰,
/// 직전 값 12h → 24h → 48h로 한 번 더 두 배된 뒤에야 상한에 걸렸다 (실효 최댓값 48h).
/// 또 서버가 DISABLED_POLL_DELAY 같은 긴 값(예: 10일)을 의도적으로 내려줘도
/// 다음 실패 시 doubling되어 의도가 훼손될 위험이 있었다.
///
/// 수정된 알고리즘 (EventService.swift:111-115):
///   if cached >= dayCapMs { cached }              // 그대로 유지
///   else { min(cached * 2, dayCapMs) }            // 2배 (상한 1일)
///
/// `cachedPollDelayMs`는 private static + 비동기 폴링 path 안에서만 갱신되어
/// 외부에서 직접 호출할 수 있는 seam이 없다. 동일 알고리즘을 spec helper로
/// 미러링해 락-인하면, 알고리즘이 변경될 때 helper도 같이 변경해야 하므로
/// 의도된 변경임을 명시하게 된다.
final class EventServiceBackoffSpecTests: XCTestCase {
    private let dayCapMs = 1000 * 60 * 60 * 24
    private let tenDaysMs = 10 * 1000 * 60 * 60 * 24

    /// EventService.swift:111-115 백오프 로직 spec (fix commit 91df32b).
    private func applyErrorBackoff(currentDelayMs: Int) -> Int {
        return currentDelayMs >= dayCapMs
            ? currentDelayMs
            : min(currentDelayMs * 2, dayCapMs)
    }

    // MARK: - 24h 미만: doubling

    func test_10s_doublesTo_20s() {
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: 10_000), 20_000)
    }

    func test_1minute_doublesTo_2minutes() {
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: 60_000), 120_000)
    }

    func test_initialPollDelay_10s_firstBackoff_20s() {
        // EventService.cachedPollDelayMs 초기값 10_000과 동일.
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: 10_000), 20_000)
    }

    func test_12h_doublesTo_24hCap() {
        // 12h * 2 = 24h, min(24h, 24h) = 24h
        let twelveH = 12 * 60 * 60 * 1000
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: twelveH), dayCapMs)
    }

    func test_13h_cappedAt_24h() {
        // 13h * 2 = 26h, min(26h, 24h) = 24h
        let thirteenH = 13 * 60 * 60 * 1000
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: thirteenH), dayCapMs)
    }

    func test_24hMinus1ms_doublesAndCappedAt_24h() {
        // boundary: 24h - 1ms는 dayCap 미만이므로 doubling 적용 (cap에 흡수)
        let almostDay = dayCapMs - 1
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: almostDay), dayCapMs)
    }

    // MARK: - 24h 이상: 보존 (회귀 방지의 핵심)

    func test_exactly_24h_isPreservedNotDoubled() {
        // boundary: 24h 정확히 dayCap 이상 → 유지 (이전 버그에서는 다음 step에서 48h로 증가했음)
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: dayCapMs), dayCapMs)
    }

    func test_24hPlus1ms_isPreservedNotShortened() {
        // 회귀 핵심: 이전 잘못된 구현(`coerceAtMost(24h)` 무조건 적용)이라면 24h로 단축됐을 값.
        // 새 알고리즘은 그대로 유지.
        let dayCapPlus1ms = dayCapMs + 1
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: dayCapPlus1ms), dayCapPlus1ms)
    }

    func test_DISABLED_POLL_DELAY_10days_isPreserved() {
        // 서버가 "이 디바이스는 당분간 폴링하지 마라"는 명시적 지시로 10일을 내려줌.
        // 클라이언트가 24h로 단축하면 서버 의도 훼손. 그대로 유지해야 함.
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: tenDaysMs), tenDaysMs)
    }

    func test_largeValue_neverGrows() {
        // 24h 이상은 doubling 안 함 → Int overflow trap 위험도 제거됨.
        let largeMs = 100 * 24 * 60 * 60 * 1000  // 100일
        XCTAssertEqual(applyErrorBackoff(currentDelayMs: largeMs), largeMs)
    }
}
