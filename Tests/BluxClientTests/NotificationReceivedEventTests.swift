import XCTest
import UIKit
import UserNotifications
@testable import BluxClient

final class NotificationReceivedEventTests: XCTestCase {
    func testInitAssignsNotification() {
        let notif = BluxNotification(id: "n", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { _ in }
        XCTAssertEqual(event.notification.id, "n")
    }

    func testToDictionaryWrapsNotification() {
        let notif = BluxNotification(id: "n", body: "B", title: "T", url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { _ in }
        let dict = event.toDictionary()
        XCTAssertNotNil(dict["notification"])
        let inner = dict["notification"] as? [String: Any]
        XCTAssertEqual(inner?["id"] as? String, "n")
    }

    // display()는 completion만 호출하고 EventService 등 외부 호출 없음. (회귀: created `received` event was duplicated)
    func testDisplayInvokesCompletionWithDefaultPresentationOptionsOnce() {
        var captured: UNNotificationPresentationOptions?
        let exp = expectation(description: "completion called exactly once")
        exp.expectedFulfillmentCount = 1
        exp.assertForOverFulfill = true

        let notif = BluxNotification(id: "x", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { options in
            captured = options
            exp.fulfill()
        }

        event.display()

        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(captured, [.alert, .sound])
    }

    func testSuppressInvokesCompletionWithEmptyOptions() {
        var captured: UNNotificationPresentationOptions?
        let exp = expectation(description: "completion called with empty options")
        let notif = BluxNotification(id: "x", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { options in
            captured = options
            exp.fulfill()
        }
        event.suppress()
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(captured, [])
    }

    func testRepeatedCallsInvokeCompletionOnlyOnce() {
        let exp = expectation(description: "completion called exactly once")
        exp.expectedFulfillmentCount = 1
        exp.assertForOverFulfill = true
        let notif = BluxNotification(id: "x", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { _ in
            exp.fulfill()
        }
        event.display()
        event.display()
        event.suppress()
        wait(for: [exp], timeout: 2.0)
    }

    func testOnCompleteFiresAfterCompletion() {
        let cExp = expectation(description: "completion")
        let oExp = expectation(description: "onComplete")
        let notif = BluxNotification(id: "x", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { _ in cExp.fulfill() }
        event.onComplete = { oExp.fulfill() }
        event.display()
        wait(for: [cExp, oExp], timeout: 2.0, enforceOrder: true)
    }

    func testDisplayDoesNotRequireClientId() {
        let savedClientId = SdkConfig.clientIdInUserDefaults
        defer { SdkConfig.clientIdInUserDefaults = savedClientId }
        SdkConfig.clientIdInUserDefaults = nil

        let exp = expectation(description: "no crash")
        let notif = BluxNotification(id: "x", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let event = NotificationReceivedEvent(notification: notif) { _ in exp.fulfill() }
        event.display()
        wait(for: [exp], timeout: 2.0)
    }
}
