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
        
        HTTPClient.shared.post(path: "/events", body: data) { (response: EventResponse?, error) in
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
    static func createClicked(notification: BluxNotification) {
        guard SdkConfig.clientIdInUserDefaults != nil else {
            Logger.error("No Client ID.")
            return
        }
        guard SdkConfig.bluxIdInUserDefaults != nil else {
            Logger.error("No Blux ID.")
            return
        }
        guard SdkConfig.deviceIdInUserDefaults != nil else {
            Logger.error("No Device ID.")
            return
        }
        
        EventService.createNotificationEvent(eventType: .clicked, notification: notification)
        
        guard let clickedHandler = EventHandlers.notificationClicked else {
            Logger.verbose("UnhandledNotification saved.")
            // If notificationClicked handler is nil, the last notification is saved and executed when the handler is registered.
            EventHandlers.unhandledNotification = notification
            return
        }
        
        Logger.verbose("NotificationClickedHandler found, execute handler.")
        clickedHandler(notification)
    }
    
    static func createReceived(notification: BluxNotification) {
        EventService.createNotificationEvent(eventType: .delivered, notification: notification)
    }
    
    static func createNotificationEvent(eventType: CRMEventType, notification: BluxNotification) {
        let data = CRMEvent(
            eventType: eventType,
            customerEngagementType: notification.customerEngagementType,
            customerEngagementId: notification.customerEngagementId,
            customerEngagementTaskId: notification.customerEngagementTaskId
        )
        
        HTTPClient.shared.post(path: "/api/v1/events", body: data, apiType: "CRM") { (response: EventResponse?, error) in
            
            if let error = error {
                Logger.error("Failed to send request.")
                Logger.error("Error: \(error)")
                return
            }
            
            if let eventResponse = response {
                Logger.verbose("\(eventResponse)")
            }
        }
    }
}
