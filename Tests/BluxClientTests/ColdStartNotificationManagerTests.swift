import XCTest
import UIKit
@testable import BluxClient

final class ColdStartNotificationManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ColdStartNotificationManager.coldStartNotification = nil
        ColdStartNotificationManager.reset()
    }

    override func tearDown() {
        ColdStartNotificationManager.coldStartNotification = nil
        ColdStartNotificationManager.reset()
        super.tearDown()
    }

    // MARK: - trackOpen dedup

    func testTrackOpenDedupsByNotificationId() {
        let n = BluxNotification(id: "uniq-csm-1", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)

        ColdStartNotificationManager.trackOpen(n)
        XCTAssertEqual(ColdStartNotificationManager.lastOpenedNotificationId, "uniq-csm-1")

        ColdStartNotificationManager.trackOpen(n)
        XCTAssertEqual(ColdStartNotificationManager.lastOpenedNotificationId, "uniq-csm-1")
    }

    func testTrackOpenAcceptsNewIdsAfterFirst() {
        let n1 = BluxNotification(id: "uniq-csm-2-a", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        let n2 = BluxNotification(id: "uniq-csm-2-b", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)

        ColdStartNotificationManager.trackOpen(n1)
        ColdStartNotificationManager.trackOpen(n2)
        XCTAssertEqual(ColdStartNotificationManager.lastOpenedNotificationId, "uniq-csm-2-b")
    }

    // reset()은 hasProcessedLaunchOptions/coldStartNotification만 비우고
    // lastOpenedNotificationId는 유지해야 한다 (didReceive가 먼저 set한 dedup 키 보존).
    func testResetPreservesLastOpenedNotificationId() {
        let n = BluxNotification(id: "uniq-csm-3", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        ColdStartNotificationManager.trackOpen(n)
        XCTAssertEqual(ColdStartNotificationManager.lastOpenedNotificationId, "uniq-csm-3")

        ColdStartNotificationManager.reset()
        XCTAssertEqual(ColdStartNotificationManager.lastOpenedNotificationId, "uniq-csm-3")
    }

    // MARK: - hasProcessedLaunchOptions guard

    // 같은 launchOptions가 페이지 전환마다 재전달되는 하이브리드 환경에서 process() 후
    // 재진입을 차단해야 한다. reset() 후엔 다시 받아들임.
    func testProcessBlocksSubsequentSetColdStartNotification() {
        let payload: [String: Any] = [
            "isBlux": true,
            "notificationId": "uniq-csm-4",
            "aps": ["alert": ["body": "B"]]
        ]
        let opts: [UIApplication.LaunchOptionsKey: Any] = [.remoteNotification: payload]

        ColdStartNotificationManager.setColdStartNotification(launchOptions: opts)
        XCTAssertNotNil(ColdStartNotificationManager.coldStartNotification)

        ColdStartNotificationManager.process()

        ColdStartNotificationManager.setColdStartNotification(launchOptions: opts)
        XCTAssertNil(ColdStartNotificationManager.coldStartNotification)

        ColdStartNotificationManager.reset()
        ColdStartNotificationManager.setColdStartNotification(launchOptions: opts)
        XCTAssertNotNil(ColdStartNotificationManager.coldStartNotification)
    }

    func testProcessIsNoopWhenNoColdStartNotification() {
        ColdStartNotificationManager.process()
        XCTAssertNil(ColdStartNotificationManager.coldStartNotification)
    }
}
