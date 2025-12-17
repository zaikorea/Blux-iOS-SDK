//
//  EventService.swift
//  BluxClient
//
//  Created by Tommy on 5/22/24.
//
import Foundation

class EventWrapper: Codable {
    let events: [Event]

    init(events: [Event]) {
        self.events = events
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
    
}
