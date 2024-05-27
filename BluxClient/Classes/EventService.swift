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
}
