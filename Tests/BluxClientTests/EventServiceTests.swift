import XCTest
@testable import BluxClient

/// EventService는 정적 상태(pendingEvents, batchWorkItem, pollTimer)를 가진다.
/// URLSession.shared를 사용해 실제 네트워크 호출이 일어나므로 발신 자체는 mock 불가.
/// 검증 가능한 부분:
/// - sendEvent에 빈 배열을 넘기면 즉시 polling 경로로 분기 (no batching)
/// - clearPendingBatch가 안전하게 호출됨
/// - flush가 안전하게 호출됨
/// - EventWrapper Codable shape (서버 contract)
final class EventServiceTests: XCTestCase {
    private var guardian: SdkStateGuard!

    override func setUp() {
        super.setUp()
        guardian = SdkStateGuard()
        guardian.clear()
        EventService.clearPendingBatch()
        EventQueue.shared.setInitialized()
        EventQueue.shared.clearPending()
    }

    override func tearDown() {
        EventService.clearPendingBatch()
        // EventQueue.shared 싱글톤이라 이 파일이 setInitialized한 상태가 후속 테스트에 누수되면
        // 영구 손상으로 이어질 수 있다. 대기 task를 비워서 다음 테스트가 깨끗한 상태로 진입하도록.
        EventQueue.shared.clearPending()
        guardian.restore()
        guardian = nil
        super.tearDown()
    }

    // MARK: - clearPendingBatch (안전성)

    func testClearPendingBatchCanBeCalledRepeatedly() {
        EventService.clearPendingBatch()
        EventService.clearPendingBatch()
        EventService.clearPendingBatch()
    }

    func testFlushCanBeCalledOnEmptyBuffer() {
        EventService.clearPendingBatch()
        EventService.flush()
    }

    func testSendEventEmptyBypassesBatch() {
        // 빈 배열은 즉시 polling 경로 (performRequest)로 분기.
        // ID가 없어 EventQueue 안에서 early return → 부작용 없음. 크래시만 안 나면 통과.
        EventService.sendEvent([])
    }

    func testSendEventBatchesSingleEvent() {
        // SdkConfig IDs가 없으니 EventQueue 내 early return.
        // 100ms batch window + 디스패치 여유 → 0.4s 대기. 부작용 검증은 어렵고 크래시 없는지만 확인.
        let event = Event(eventType: "x")
        EventService.sendEvent([event])

        let exp = expectation(description: "batch flush window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        EventService.clearPendingBatch()
    }

    // MARK: - EventWrapper 인코딩 (서버 contract)

    func testEventWrapperEncodesEventsAndDeviceId() throws {
        SdkConfig.sessionId = "S"
        let events = [Event(eventType: "visit"), Event(eventType: "click")]
        let wrapper = EventWrapper(events: events, deviceId: "D-1")

        let data = try JSONEncoder().encode(wrapper)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["device_id"] as? String, "D-1")
        let evts = dict["events"] as! [[String: Any]]
        XCTAssertEqual(evts.count, 2)
        XCTAssertEqual(evts[0]["event_type"] as? String, "visit")
        XCTAssertEqual(evts[1]["event_type"] as? String, "click")
    }

    func testEventWrapperEmptyEventsArray() throws {
        let wrapper = EventWrapper(events: [], deviceId: "D-2")
        let data = try JSONEncoder().encode(wrapper)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let evts = dict["events"] as! [[String: Any]]
        XCTAssertTrue(evts.isEmpty)
        XCTAssertEqual(dict["device_id"] as? String, "D-2")
    }

    // SdkConfig IDs가 nil인 상태에서 sendEvent가 호출되면 EventQueue 안에서 early return + done()이
    // 호출되어 후속 task가 starvation되지 않아야 한다.
    // (회귀: HTTPClient.invalidRequest 시 completion 미호출 → done 미호출 → EventQueue 영구 정지)
    func testSendEventDoesNotStarveEventQueueWhenNoIds() {
        EventQueue.shared.setInitialized()
        EventQueue.shared.clearPending()

        let drain = expectation(description: "drain")
        EventQueue.shared.addEvent { drain.fulfill() }
        wait(for: [drain], timeout: 2.0)

        EventService.sendEvent([Event(eventType: "x")])

        // 100ms batch window + EventQueue dispatch + invalidRequest 경로의 done() 호출. CI 여유로 0.6s.
        let postBatch = expectation(description: "post-batch sentinel")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            EventQueue.shared.addEvent { postBatch.fulfill() }
        }
        wait(for: [postBatch], timeout: 5.0)
    }
}
