//
//  EventService.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//

import Foundation

class EventService {
    /// Send request
    /// - Parameters:
    ///   - data: event data
    static func sendRequest<T: Codable>(_ data: [T]) {
        
        HTTPClient.shared.post(path: "/events", body: data, apiType: "LEGACY") { (response: EventResponse?, error) in
            if let error = error {
                Logger.error("Failed to send event request.")
                Logger.error("Error: \(error)")
                return
            }
            
            if let eventResponse = response {
                Logger.verbose("\(eventResponse)")
            }
        }
    }
    
    /// Processed when notification is clicked
    /// - Parameter notification: Received notification
    static func createPushOpened(notification: BluxNotification) {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return
        }
        
        // Define the Codable struct with custom encoding for the Date field
        struct CRMEventsBody: Codable {
            let notification_id: String
            let crm_event_type: String
            let captured_at: String
        }
        
        // 현재 날짜와 시간을 나타내는 Date 객체
        let capturedAt = Date()

        // DateFormatter 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // 원하는 날짜 형식 설정 (ISO 8601 형식 예시)
        let capturedAtString = dateFormatter.string(from: capturedAt)
        struct EmptyResponse: Codable {}

        HTTPClient.shared.post(path: "/organizations/" + clientId + "/crm-events", body: CRMEventsBody(notification_id: notification.id, crm_event_type: "push_opened", captured_at: capturedAtString)) { (response: EmptyResponse?, error) in
            
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
    
    open class BluxNotificationResponse: Codable {
        public var id: String
        
        public init(id: String) {
            self.id = id
        }
    }
    
    static func createReceived(notification: BluxNotification) {
        guard let clientId = UserDefaults(suiteName: "group.ai.blux.app")?.string(forKey: "bluxClientId") else {
            return
        }

        struct StatusBody: Codable {
            let status: String
        }
        

        HTTPClient.shared.post(path: "/organizations/" + clientId + "/notifications/" + notification.id, body: StatusBody(status: "received")) { (response: BluxNotificationResponse?, error) in
            
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }
            
            if let notificationResponse = response {
                Logger.verbose("SetCustomUserProperties request success.")
                Logger.verbose("Notification ID: " + notificationResponse.id)
            }
        }
    }
}
