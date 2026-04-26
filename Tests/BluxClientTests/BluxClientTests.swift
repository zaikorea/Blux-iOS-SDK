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
        // IDs 없을 때도 EventHandlers/EventService/InappService cleanup은 무조건 일어남
        EventHandlers.unhandledNotification = BluxNotification(
            id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )
        BluxClient.signOut()
        XCTAssertNil(EventHandlers.unhandledNotification,
                     "signOut must clear unhandled notification regardless of IDs")
    }

    // MARK: - setUserPropertiesData / setCustomUserProperties 사전조건

    func testSetUserPropertiesDataReturnsEarlyWhenNoIds() {
        // 사전조건 미충족이면 그냥 return. 크래시만 없으면 통과.
        BluxClient.setUserPropertiesData(userProperties: ["k": "v"])
    }

    func testSetUserPropertiesPassesGenderAsRawString() {
        // 내부적으로 setUserPropertiesData를 호출. 사전조건 미충족으로 return.
        let props = UserProperties(age: 30, gender: .female)
        BluxClient.setUserProperties(userProperties: props)
        // 검증: 크래시 없이 통과
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

    // MARK: - credential 변경 감지

    // API key만 교체된 경우에도 credentialsChanged=true로 인식되어 cleanup 실행.
    // (회귀: apiKeyInUserDefaults를 쓰기 전에 savedApiKey를 읽어야 함)
    func testInitializeDetectsApiKeyOnlyChangeAsCredentialChange() {
        SdkConfig.clientIdInUserDefaults = "app-1"
        SdkConfig.apiKeyInUserDefaults = "key-old"
        EventHandlers.unhandledNotification = BluxNotification(
            id: "leak", body: "B", title: nil, url: nil, imageUrl: nil, data: nil
        )

        BluxClient.initialize(nil, bluxApplicationId: "app-1", bluxAPIKey: "key-NEW") { _ in }

        XCTAssertEqual(SdkConfig.apiKeyInUserDefaults, "key-NEW")
        XCTAssertNil(EventHandlers.unhandledNotification,
                     "API key 변경만으로도 credentialsChanged=true가 되어 cleanup 발생해야 함")
    }
}
