import XCTest
import UserNotifications
@testable import BluxClient

final class BluxNotificationServiceExtensionTests: XCTestCase {
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

    func testDidReceiveDeliversContentOnceForNonBluxPush() {
        let content = UNMutableNotificationContent()
        content.userInfo = ["foo": "bar"]
        let request = UNNotificationRequest(identifier: "non-blux", content: content, trigger: nil)

        let exp = expectation(description: "contentHandler invoked")
        exp.assertForOverFulfill = true
        BluxNotificationServiceExtensionHelper.shared.didReceive(request) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testDidReceiveDeliversContentOnceForBluxPushWithoutClientId() {
        let content = UNMutableNotificationContent()
        content.userInfo = [
            "isBlux": true,
            "notificationId": "abc",
            "aps": ["alert": ["body": "hi"]],
        ]
        let request = UNNotificationRequest(identifier: "blux", content: content, trigger: nil)

        let exp = expectation(description: "contentHandler invoked exactly once")
        exp.assertForOverFulfill = true
        BluxNotificationServiceExtensionHelper.shared.didReceive(request) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }
}
