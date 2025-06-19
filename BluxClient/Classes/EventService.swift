//
//  EventService.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//
import Foundation

// Define the Codable struct with custom encoding for the Date field
struct CRMEventsBody: Codable {
    let notification_id: String
    let crm_event_type: String
    let captured_at: String
}

struct EmptyResponse: Codable {}

class EventWrapper: Codable {
    let events: [Event]

    public init(events: [Event]) {
        self.events = events
    }
}

struct BluxNotificationResponse: Codable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
    }
}

class EventService {
    /// Send request
    /// - Parameters:
    ///   - data: event data
    static func sendEvent(
        _ data: [Event]
    ) {
        let eventTask = {
            guard let clientId = SdkConfig.clientIdInUserDefaults,
                  let bluxId = SdkConfig.bluxIdInUserDefaults
            else {
                return
            }

            HTTPClient.shared.post(
                path:
                "/applications/\(clientId)/blux-users/\(bluxId)/collect-events",
                body: EventWrapper(events: data)
            ) { (_: EmptyResponse?, error) in
                if let error = error {
                    Logger.error("Failed to send event request: \(error)")
                    return
                }
            }
        }
        EventQueue.shared.addEvent(eventTask)
    }

    /// Processed when notification is clicked
    /// - Parameter notification: Received notification
    static func createPushOpened(notification: BluxNotification) {
        let eventTask = {
            guard let clientId = SdkConfig.clientIdInUserDefaults else {
                return
            }

            let capturedAtString = ISO8601DateFormatter().string(from: Date())

            HTTPClient.shared.post(
                path: "/applications/" + clientId + "/crm-events",
                body: CRMEventsBody(
                    notification_id: notification.id,
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

            guard let clickedHandler = EventHandlers.notificationClicked else {
                Logger.verbose("UnhandledNotification saved.")
                // If notificationClicked handler is nil, the last notification is saved and executed when the handler is registered.
                EventHandlers.unhandledNotification = notification
                return
            }

            Logger.verbose("NotificationClickedHandler found, execute handler.")
            clickedHandler(notification)
        }

        EventQueue.shared.addEvent(eventTask)
    }

    static func createInappOpened(_ notificationId: String) {
        let eventTask = {
            guard let clientId = SdkConfig.clientIdInUserDefaults else {
                return
            }

            let capturedAtString = ISO8601DateFormatter().string(from: Date())

            Logger.verbose("capturedAt: \(capturedAtString)")

            HTTPClient.shared.post(
                path: "/applications/" + clientId + "/crm-events",
                body: CRMEventsBody(
                    notification_id: notificationId,
                    crm_event_type: "inapp_opened",
                    captured_at: capturedAtString
                )
            ) { (_: EmptyResponse?, error) in
                if let error = error {
                    Logger.error("Failed to send request.")
                    Logger.error("Error: \(error)")
                    return
                }
            }
        }

        EventQueue.shared.addEvent(eventTask)
    }

    static func createReceived(_ notificationId: String) {
        let eventTask = {
            Logger.error(SdkConfig.bluxSuiteName ?? "nil")
            guard
                let clientId = UserDefaults(suiteName: SdkConfig.bluxSuiteName)?
                .string(forKey: "bluxClientId")
            else {
                return
            }

            struct StatusBody: Codable {
                let status: String
            }

            HTTPClient.shared.post(
                path: "/applications/" + clientId + "/notifications/"
                    + notificationId, body: StatusBody(status: "received")
            ) { (response: BluxNotificationResponse?, error) in

                if let error = error {
                    Logger.error("Failed to send request.")
                    Logger.error("Error: \(error)")
                    return
                }

                if let notificationResponse = response {
                    Logger.verbose("Create Received request success.")
                    Logger.verbose(
                        "Notification ID: " + notificationResponse.id)
                }
            }
        }

        EventQueue.shared.addEvent(eventTask)
    }
}
