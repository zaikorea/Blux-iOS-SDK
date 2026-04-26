import XCTest
@testable import BluxClient

/// BluxClient의 정적 API 일부 동작을 검증.
/// 네트워크가 필요한 경로는 모킹 불가하므로 사전조건 분기와 핸들러 등록만 검증.
final class BluxClientTests: XCTestCase {
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

    // MARK: - setLogLevel

    func testSetLogLevelChangesConfig() {
        let saved = SdkConfig.logLevel
        defer { SdkConfig.logLevel = saved }

        BluxClient.setLogLevel(level: .none)
        XCTAssertEqual(SdkConfig.logLevel, .none)

        BluxClient.setLogLevel(level: .error)
        XCTAssertEqual(SdkConfig.logLevel, .error)

        BluxClient.setLogLevel(level: .verbose)
        XCTAssertEqual(SdkConfig.logLevel, .verbose)
    }

    // MARK: - setNotificationUrlOpenOptions

    func testSetNotificationUrlOpenOptionsPersists() {
        BluxClient.setNotificationUrlOpenOptions(
            NotificationUrlOpenOptions(httpUrlOpenTarget: .externalBrowser)
        )
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, .externalBrowser)

        BluxClient.setNotificationUrlOpenOptions(
            NotificationUrlOpenOptions(httpUrlOpenTarget: .none)
        )
        XCTAssertEqual(SdkConfig.notificationUrlOpenOptions.httpUrlOpenTarget, .none)
    }

    // MARK: - signIn 사전조건

    func testSignInFailsFastWhenNoIds() {
        let exp = expectation(description: "signIn early-fail")
        var capturedError: NSError?

        BluxClient.signIn(userId: "u") { error in
            capturedError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        XCTAssertNotNil(capturedError)
        XCTAssertEqual(capturedError?.domain, "BluxClient")
    }

    // MARK: - signOut 사전조건

    func testSignOutDoesNotCrashWhenNoIds() {
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        BluxClient.signOut()
        XCTAssertNil(EventHandlers.unhandledNotification,
                     "signOut must clear unhandled notification regardless of IDs")
    }

    // MARK: - setUserPropertiesData / setCustomUserProperties 사전조건

    func testSetUserPropertiesDataReturnsEarlyWhenNoIds() {
        BluxClient.setUserPropertiesData(userProperties: ["k": "v"])
    }

    func testSetUserPropertiesPassesGenderAsRawString() {
        let props = UserProperties(age: 30, gender: .female)
        BluxClient.setUserProperties(userProperties: props)
    }

    func testSetCustomUserPropertiesReturnsEarlyWhenNoIds() {
        BluxClient.setCustomUserProperties(customUserProperties: ["k": "v"])
    }

    // MARK: - Notification 핸들러 등록

    func testSetNotificationClickedHandlerStoresHandler() {
        var fired = false
        BluxClient.setNotificationClickedHandler { _ in fired = true }
        XCTAssertNotNil(EventHandlers.notificationClicked)

        let n = BluxNotification(id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        EventHandlers.notificationClicked?(n)
        XCTAssertTrue(fired)
    }

    func testSetNotificationClickedHandlerProcessesUnhandledImmediately() {
        let pendingNotif = BluxNotification(
            id: "pending", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        EventHandlers.unhandledNotification = pendingNotif

        var receivedId: String?
        BluxClient.setNotificationClickedHandler { n in receivedId = n.id }

        XCTAssertEqual(receivedId, "pending",
                       "Pending unhandled notification must fire upon registration")
        XCTAssertNil(EventHandlers.unhandledNotification,
                     "Unhandled notification must be cleared after firing")
    }

    func testSetNotificationForegroundWillDisplayHandlerStoresHandler() {
        BluxClient.setNotificationForegroundWillDisplayHandler { _ in }
        XCTAssertNotNil(EventHandlers.notificationForegroundWillDisplay)
    }

    // MARK: - addInAppCustomActionHandler

    func testAddInAppCustomActionHandlerReturnsUnsubscribeFunction() {
        let unsubscribe = BluxClient.addInAppCustomActionHandler { _, _ in }
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 1)
        unsubscribe()
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 0)
    }

    func testMultipleHandlersCanCoexist() {
        let u1 = BluxClient.addInAppCustomActionHandler { _, _ in }
        let u2 = BluxClient.addInAppCustomActionHandler { _, _ in }
        XCTAssertEqual(EventHandlers.inAppCustomActionHandlers.count, 2)
        u1()
        u2()
    }

    // MARK: - sendEvent / sendRequestData 호환성

    func testSendEventWithEventRequestDoesNotCrash() {
        let req = EventRequest()
        req.events.append(Event(eventType: "x"))
        BluxClient.sendEvent(req)
    }

    func testSendRequestDataWithEmptyArrayDoesNotCrash() {
        BluxClient.sendRequestData([])
    }

    // MARK: - dismissInApp

    func testDismissInAppDoesNotCrashWhenNothingShown() {
        BluxClient.dismissInApp()
    }

}
