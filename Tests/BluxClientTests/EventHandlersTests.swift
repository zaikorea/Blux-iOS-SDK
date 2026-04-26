import XCTest
@testable import BluxClient

/// EventHandlers는 enum 기반 정적 슬롯이라 테스트 간 격리에 주의.
/// 매 테스트 setUp/tearDown에서 모든 슬롯을 비운다.
final class EventHandlersTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearAll()
    }

    override func tearDown() {
        clearAll()
        super.tearDown()
    }

    private func clearAll() {
        EventHandlers.unhandledNotification = nil
        EventHandlers.notificationForegroundWillDisplay = nil
        EventHandlers.notificationClicked = nil
        EventHandlers.inAppCustomActionHandlers = []
    }

    // MARK: - 단일 핸들러 슬롯

    func testUnhandledNotificationSlotStartsNil() {
        XCTAssertNil(EventHandlers.unhandledNotification)
    }

    func testUnhandledNotificationStoresAndRetrieves() {
        let n = BluxNotification(id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        EventHandlers.unhandledNotification = n
        XCTAssertNotNil(EventHandlers.unhandledNotification)
        XCTAssertEqual(EventHandlers.unhandledNotification?.id, "n")
    }

    func testNotificationClickedSlotStoresClosure() {
        var captured: BluxNotification?
        EventHandlers.notificationClicked = { n in captured = n }

        let n = BluxNotification(id: "x", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        EventHandlers.notificationClicked?(n)
        XCTAssertEqual(captured?.id, "x")
    }

    // MARK: - inAppCustomActionHandlers

    func testInAppHandlerListStartsEmpty() {
        XCTAssertTrue(EventHandlers.inAppCustomActionHandlers.isEmpty)
    }

    func testAddInAppCustomActionHandlerRegistersOne() {
        var calledWith: (String, [String: Any])?
        let unsubscribe = BluxClient.addInAppCustomActionHandler { actionId, data in
            calledWith = (actionId, data)
        }

        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 1)

        // 등록된 handler 직접 invoke
        EventHandlers.inAppCustomActionHandlers[0].handler("share", ["url": "https://x"])
        XCTAssertEqual(calledWith?.0, "share")
        XCTAssertEqual(calledWith?.1["url"] as? String, "https://x")

        // unsubscribe
        unsubscribe()
        XCTAssertTrue(EventHandlers.inAppCustomActionHandlers.isEmpty)
    }

    func testAddInAppCustomActionHandlerRegistersMultiple() {
        let u1 = BluxClient.addInAppCustomActionHandler { _, _ in }
        let u2 = BluxClient.addInAppCustomActionHandler { _, _ in }
        let u3 = BluxClient.addInAppCustomActionHandler { _, _ in }

        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 3)

        u2()
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 2)

        u1()
        u3()
        XCTAssertTrue(EventHandlers.inAppCustomActionHandlers.isEmpty)
    }

    func testAddInAppCustomActionHandlerEachHasUniqueId() {
        _ = BluxClient.addInAppCustomActionHandler { _, _ in }
        _ = BluxClient.addInAppCustomActionHandler { _, _ in }

        let ids = EventHandlers.inAppCustomActionHandlers.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Each handler must have a unique id")
    }

    func testUnsubscribeIsIdempotent() {
        let unsubscribe = BluxClient.addInAppCustomActionHandler { _, _ in }
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 1)
        unsubscribe()
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 0)
        unsubscribe() // 두 번째 호출도 안전
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 0)
    }

    func testHandlersExecuteInRegistrationOrder() {
        var sequence: [Int] = []
        _ = BluxClient.addInAppCustomActionHandler { _, _ in sequence.append(1) }
        _ = BluxClient.addInAppCustomActionHandler { _, _ in sequence.append(2) }
        _ = BluxClient.addInAppCustomActionHandler { _, _ in sequence.append(3) }

        for entry in EventHandlers.inAppCustomActionHandlers {
            entry.handler("any", [:])
        }
        XCTAssertEqual(sequence, [1, 2, 3])
    }
}
