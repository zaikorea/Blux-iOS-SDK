import XCTest
@testable import BluxClient

/// EventQueue.shared는 SDK 초기화 전후 이벤트 순서를 보장하는 직렬 큐. 싱글톤이라 테스트 간 격리에 주의.
/// setUp에서 setInitialized + clearPending + 동기 wait로 isInitialized=true 보장 후 매 테스트 진입.
///
/// CI(특히 simulator 콜드스타트 직후)에서 `DispatchQueue.global()` 워커가 일시적으로 starvation
/// 상태가 되어 비동기 task가 수 초 지연될 수 있다. 따라서 wait timeout은 넉넉하게 잡는다 (race 방지).
/// 단, expectation 자체는 충족 즉시 통과하므로 정상 환경에서 실제 대기 시간이 늘지 않는다.
final class EventQueueTests: XCTestCase {
    override func setUp() {
        super.setUp()
        EventQueue.shared.setInitialized()
        EventQueue.shared.clearPending()
        // EventQueue 내부 큐의 비동기 작업이 모두 dispatch 되도록 sentinel task로 동기화
        let exp = expectation(description: "drain")
        EventQueue.shared.addEvent { exp.fulfill() }
        wait(for: [exp], timeout: 15.0)
    }

    // MARK: - 동기 task

    func testSynchronousTaskExecutes() {
        let exp = expectation(description: "task")
        EventQueue.shared.addEvent {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 15.0)
    }

    func testMultipleSynchronousTasksExecuteInOrder() {
        let count = 20
        var order: [Int] = []
        let lock = NSLock()
        let exp = expectation(description: "all done")
        exp.expectedFulfillmentCount = count

        for i in 0..<count {
            EventQueue.shared.addEvent {
                lock.lock(); order.append(i); lock.unlock()
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 15.0)
        XCTAssertEqual(order, Array(0..<count), "Events must run in insertion order")
    }

    // MARK: - 비동기 task

    func testAsyncTaskCompletesBeforeNext() {
        var sequence: [String] = []
        let lock = NSLock()
        let exp = expectation(description: "both done")
        exp.expectedFulfillmentCount = 2

        EventQueue.shared.addEvent { (done: @escaping () -> Void) in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                lock.lock(); sequence.append("first-finished"); lock.unlock()
                done()
                exp.fulfill()
            }
        }
        EventQueue.shared.addEvent {
            lock.lock(); sequence.append("second-started"); lock.unlock()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 20.0)
        XCTAssertEqual(sequence, ["first-finished", "second-started"],
                       "Second task must wait for first's done()")
    }

    /// done() 미호출 시 큐가 영구 락된다는 사실은 코드 리뷰로 자명하지만
    /// 싱글톤 EventQueue.shared의 isProcessing을 회복할 방법이 없어 다른 테스트를 망가뜨린다.
    /// 따라서 이 시나리오는 단위 테스트로 검증하지 않는다.

    // MARK: - clearPending

    func testClearPendingDropsWaitingTasks() {
        let firstExp = expectation(description: "first")
        let droppedExp = expectation(description: "dropped (should not run)")
        droppedExp.isInverted = true

        // 첫 task를 충분히 길게 잡아 두 번째가 대기 상태로 들어가게 함. CI 부하 시 race 방지를 위해 buffer 여유.
        EventQueue.shared.addEvent { (done: @escaping () -> Void) in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
                firstExp.fulfill()
                done()
            }
        }
        EventQueue.shared.addEvent {
            droppedExp.fulfill()
        }

        // 첫 task가 실행 중이고 두 번째가 대기 중일 때 clearPending
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            EventQueue.shared.clearPending()
        }

        wait(for: [firstExp, droppedExp], timeout: 20.0)
    }

    func testClearPendingDoesNotResetInitialized() {
        // clearPending 후에도 신규 addEvent는 정상 처리돼야 함
        EventQueue.shared.clearPending()
        let exp = expectation(description: "new task after clear")
        EventQueue.shared.addEvent {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 15.0)
    }

    // MARK: - shared 싱글톤

    func testSharedIsSingleton() {
        XCTAssertTrue(EventQueue.shared === EventQueue.shared)
    }

    // MARK: - setInitialized idempotency

    // setInitialized가 중복 호출돼도 진행 중인 task를 깨뜨리지 않아야 한다.
    func testSetInitializedIsIdempotent() {
        EventQueue.shared.setInitialized()
        EventQueue.shared.setInitialized()
        EventQueue.shared.setInitialized()

        let exp = expectation(description: "task after multi setInitialized")
        EventQueue.shared.addEvent { exp.fulfill() }
        wait(for: [exp], timeout: 15.0)
    }

    // clearPending 후에도 isInitialized 상태가 유지되어 신규 addEvent가 정상 처리.
    func testClearPendingPreservesInitialized() {
        EventQueue.shared.clearPending()

        let exp = expectation(description: "task after clearPending")
        EventQueue.shared.addEvent { exp.fulfill() }
        wait(for: [exp], timeout: 15.0)
    }
}
