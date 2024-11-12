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

class EventService {
    /// Send request
    /// - Parameters:
    ///   - data: event data
    static func sendRequest(
        _ data: [Event],
        _ completionHandler: @escaping (Event?, Error?) -> Void
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
            ) { (response: EventResponse?, error) in
                if let error = error {
                    Logger.error("Failed to send event request: \(error)")
                    return
                }
                if let eventResponse = response {
                    data.forEach { event in
                        completionHandler(event, error)
                    }
                    Logger.verbose("\(eventResponse)")
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

            // 현재 날짜와 시간을 나타내는 Date 객체
            let capturedAt = Date()

            // DateFormatter 생성
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"  // 원하는 날짜 형식 설정 (ISO 8601 형식 예시)
            let capturedAtString = dateFormatter.string(from: capturedAt)

            HTTPClient.shared.post(
                path: "/applications/" + clientId + "/crm-events",
                body: CRMEventsBody(
                    notification_id: notification.id,
                    crm_event_type: "push_opened",
                    captured_at: capturedAtString
                )
            ) { (response: EmptyResponse?, error) in
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

    open class BluxNotificationResponse: Codable {
        public var id: String

        public init(id: String) {
            self.id = id
        }
    }

    static func createReceived(notification: BluxNotification) {
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
                    + notification.id, body: StatusBody(status: "received")
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
