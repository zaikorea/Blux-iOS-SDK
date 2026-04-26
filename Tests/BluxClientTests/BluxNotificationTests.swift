import XCTest
import UIKit
@testable import BluxClient

final class BluxNotificationTests: XCTestCase {
    // MARK: - Init

    func testInitAssignsAllProperties() {
        let notif = BluxNotification(
            id: "n1",
            body: "Hello",
            title: "Title",
            url: "https://example.com",
            imageUrl: "https://img.example.com/i.png",
            data: ["foo": "bar"]
        )
        XCTAssertEqual(notif.id, "n1")
        XCTAssertEqual(notif.body, "Hello")
        XCTAssertEqual(notif.title, "Title")
        XCTAssertEqual(notif.url, "https://example.com")
        XCTAssertEqual(notif.imageUrl, "https://img.example.com/i.png")
        XCTAssertEqual(notif.data?["foo"] as? String, "bar")
    }

    func testInitConvertsEmptyStringsToNil() {
        let notif = BluxNotification(
            id: "n1",
            body: "Hello",
            title: "",
            url: "",
            imageUrl: "",
            data: nil
        )
        XCTAssertNil(notif.title)
        XCTAssertNil(notif.url)
        XCTAssertNil(notif.imageUrl)
    }

    func testInitNilStringsRemainNil() {
        let notif = BluxNotification(
            id: "n1",
            body: "Hello",
            title: nil,
            url: nil,
            imageUrl: nil,
            data: nil
        )
        XCTAssertNil(notif.title)
        XCTAssertNil(notif.url)
        XCTAssertNil(notif.imageUrl)
    }

    // MARK: - getBluxNotificationFromUserInfo

    private let validUserInfo: [AnyHashable: Any] = [
        "isBlux": true,
        "notificationId": "abc",
        "aps": [
            "alert": [
                "body": "Hello body",
                "title": "Hello title"
            ]
        ],
        "url": "https://blux.ai",
        "imageUrl": "https://img",
        "data": ["k": "v"]
    ]

    func testGetFromUserInfoValid() {
        let notif = BluxNotification.getBluxNotificationFromUserInfo(userInfo: validUserInfo)
        XCTAssertNotNil(notif)
        XCTAssertEqual(notif?.id, "abc")
        XCTAssertEqual(notif?.body, "Hello body")
        XCTAssertEqual(notif?.title, "Hello title")
        XCTAssertEqual(notif?.url, "https://blux.ai")
        XCTAssertEqual(notif?.imageUrl, "https://img")
        XCTAssertEqual(notif?.data?["k"] as? String, "v")
    }

    func testGetFromUserInfoMissingIsBluxReturnsNil() {
        var info = validUserInfo
        info.removeValue(forKey: "isBlux")
        XCTAssertNil(BluxNotification.getBluxNotificationFromUserInfo(userInfo: info))
    }

    func testGetFromUserInfoIsBluxFalseReturnsNil() {
        var info = validUserInfo
        info["isBlux"] = false
        XCTAssertNil(BluxNotification.getBluxNotificationFromUserInfo(userInfo: info))
    }

    func testGetFromUserInfoMissingNotificationIdReturnsNil() {
        var info = validUserInfo
        info.removeValue(forKey: "notificationId")
        XCTAssertNil(BluxNotification.getBluxNotificationFromUserInfo(userInfo: info))
    }

    func testGetFromUserInfoMissingApsReturnsNil() {
        var info = validUserInfo
        info.removeValue(forKey: "aps")
        XCTAssertNil(BluxNotification.getBluxNotificationFromUserInfo(userInfo: info))
    }

    func testGetFromUserInfoMissingAlertReturnsNil() {
        var info = validUserInfo
        info["aps"] = ["badge": 1]
        XCTAssertNil(BluxNotification.getBluxNotificationFromUserInfo(userInfo: info))
    }

    func testGetFromUserInfoMissingBodyReturnsNil() {
        var info = validUserInfo
        info["aps"] = ["alert": ["title": "T"]]
        XCTAssertNil(BluxNotification.getBluxNotificationFromUserInfo(userInfo: info))
    }

    func testGetFromUserInfoOptionalFieldsCanBeMissing() {
        let minimal: [AnyHashable: Any] = [
            "isBlux": true,
            "notificationId": "id",
            "aps": ["alert": ["body": "B"]]
        ]
        let notif = BluxNotification.getBluxNotificationFromUserInfo(userInfo: minimal)
        XCTAssertNotNil(notif)
        XCTAssertNil(notif?.title)
        XCTAssertNil(notif?.url)
        XCTAssertNil(notif?.imageUrl)
        XCTAssertNil(notif?.data)
    }

    func testGetFromUserInfoEmptyTitleBecomesNil() {
        var info = validUserInfo
        info["aps"] = ["alert": ["body": "B", "title": ""]]
        let notif = BluxNotification.getBluxNotificationFromUserInfo(userInfo: info)
        XCTAssertNotNil(notif)
        XCTAssertNil(notif?.title)
    }

    // MARK: - getBluxNotificationFromLaunchOptions

    func testGetFromLaunchOptionsNilReturnsNil() {
        let result = BluxNotification.getBluxNotificationFromLaunchOptions(launchOptions: nil)
        XCTAssertNil(result)
    }

    func testGetFromLaunchOptionsWithoutRemoteNotificationReturnsNil() {
        let opts: [UIApplication.LaunchOptionsKey: Any] = [
            .url: URL(string: "blux://test")!
        ]
        XCTAssertNil(BluxNotification.getBluxNotificationFromLaunchOptions(launchOptions: opts))
    }

    func testGetFromLaunchOptionsValidPayload() {
        let payload: [String: Any] = [
            "isBlux": true,
            "notificationId": "n",
            "aps": ["alert": ["body": "B"]]
        ]
        let opts: [UIApplication.LaunchOptionsKey: Any] = [
            .remoteNotification: payload
        ]
        let notif = BluxNotification.getBluxNotificationFromLaunchOptions(launchOptions: opts)
        XCTAssertNotNil(notif)
        XCTAssertEqual(notif?.id, "n")
    }

    func testGetFromLaunchOptionsInvalidPayloadReturnsNil() {
        let payload: [String: Any] = ["isBlux": false]
        let opts: [UIApplication.LaunchOptionsKey: Any] = [
            .remoteNotification: payload
        ]
        XCTAssertNil(BluxNotification.getBluxNotificationFromLaunchOptions(launchOptions: opts))
    }

    // MARK: - toDictionary

    func testToDictionaryProducesAllKeys() {
        let notif = BluxNotification(
            id: "n",
            body: "B",
            title: "T",
            url: "U",
            imageUrl: "I",
            data: ["k": "v"]
        )
        let dict = notif.toDictionary()
        XCTAssertEqual(dict["id"] as? String, "n")
        XCTAssertEqual(dict["body"] as? String, "B")
        XCTAssertEqual(dict["title"] as? String, "T")
        XCTAssertEqual(dict["url"] as? String, "U")
        XCTAssertEqual(dict["imageUrl"] as? String, "I")
        XCTAssertNotNil(dict["data"] as? [String: Any])
    }

    // MARK: - description

    func testDescriptionContainsId() {
        let notif = BluxNotification(id: "abc", body: "B", title: nil, url: nil, imageUrl: nil, data: nil)
        XCTAssertTrue(notif.description.contains("abc"))
    }
}
