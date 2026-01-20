//
//  BluxNotification.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation
import UIKit
import UserNotifications

struct CRMEventsBody: Codable {
    let notification_id: String
    let crm_event_type: String
    let captured_at: String
}

struct BluxNotificationResponse: Codable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
    }
}

@objc open class BluxNotification: NSObject {
    public var id: String
    public var body: String
    public var title: String?
    public var url: String?
    public var imageUrl: String?
    public var data: [String: Any]?

    public init(id: String, body: String, title: String?, url: String?, imageUrl: String?, data: [String: Any]?) {
        self.id = id
        self.body = body
        self.title = title == "" ? nil : title
        self.url = url == "" ? nil : url
        self.imageUrl = imageUrl == "" ? nil : imageUrl
        self.data = data
    }

    override open var description: String {
        var properties: [String] = []

        properties.append(id)
        properties.append(body)
        properties.append(String(describing: title))
        properties.append(String(describing: url))
        properties.append(String(describing: imageUrl))
        properties.append(String(describing: data))

        return "\n\t\(properties.joined(separator: "\n\t"))\n"
    }

    static func getBluxNotificationFromUserInfo(userInfo: [AnyHashable: Any]) -> BluxNotification? {
        let isBlux = userInfo["isBlux"] as? Bool
        if isBlux != true {
            Logger.error("Not a notification from Blux.")
            return nil
        }

        guard let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let notificationId = userInfo["notificationId"] as? String,
              let body = alert["body"] as? String
        else {
            Logger.error("Failed to get BluxNotification: Missing required keys")
            return nil
        }

        let notification = BluxNotification(
            id: notificationId,
            body: body,
            title: alert["title"] as? String,
            url: userInfo["url"] as? String,
            imageUrl: userInfo["imageUrl"] as? String,
            data: userInfo["data"] as? [String: Any]
        )

        return notification
    }

    static func getBluxNotificationFromLaunchOptions(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BluxNotification? {
        guard let userInfo = launchOptions?[.remoteNotification] as? [String: Any], // Check is launched via push notification
              let notification = BluxNotification.getBluxNotificationFromUserInfo(userInfo: userInfo)
        else {
            return nil
        }

        Logger.verbose("Enter app via push notification.")

        return notification
    }

    public static func getBluxNotificationFromUNNotificationContent(_ notificationContent: UNNotificationContent) -> BluxNotification? {
        guard let bluxNotification = BluxNotification.getBluxNotificationFromUserInfo(userInfo: notificationContent.userInfo) else {
            return nil
        }

        return bluxNotification
    }

    public func toDictionary() -> [String: Any?] {
        let dict: [String: Any?] = [
            "id": id,
            "body": body,
            "title": title,
            "url": url,
            "imageUrl": imageUrl,
            "data": data,
        ]

        return dict
    }

    /// Track notification opened event and execute handler
    func trackOpened() {
        guard let clientId = SdkConfig.clientIdInUserDefaults else { return }

        let capturedAtString = ISO8601DateFormatter().string(from: Date())

        HTTPClient.shared.post(
            path: "/applications/" + clientId + "/crm-events",
            body: CRMEventsBody(
                notification_id: self.id,
                crm_event_type: "push_opened",
                captured_at: capturedAtString
            )
        ) { (_: EmptyResponse?, error) in
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }
        }

        if let clickedHandler = EventHandlers.notificationClicked {
            Logger.verbose("NotificationClickedHandler found, execute handler.")
            clickedHandler(self)
        } else {
            Logger.verbose("UnhandledNotification saved.")
            // If notificationClicked handler is nil, the last notification is saved and executed when the handler is registered.
            EventHandlers.unhandledNotification = self
        }
    }

        /// Track notification received event
    func trackReceived() {
        guard let clientId = SdkConfig.clientIdInUserDefaults else { return }

        struct StatusBody: Codable {
            let status: String
        }

        HTTPClient.shared.post(
            path: "/applications/" + clientId + "/notifications/" + self.id,
            body: StatusBody(status: "received")
        ) { (response: BluxNotificationResponse?, error) in
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }

            if let notificationResponse = response {
                Logger.verbose("Create Received request success.")
                Logger.verbose("Notification ID: " + notificationResponse.id)
            }
        }
    }
}
