import Foundation

public class Event: Codable {
    
    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var itemId: String? = nil
    public var timestamp: Double = Utils.getCurrentUnixTimestamp()
    public var eventType: String
    public var eventValue: String? = nil
    public var from: String? = nil
    public var url: String? = nil
    public var ref: String? = nil
    public var recommendationId: String? = nil
    public var eventProperties: [String: String]? = nil
    public var userProperties: [String: String]? = nil
    
    enum CodingKeys: String,
                     CodingKey {
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case itemId = "item_id"
        case timestamp = "timestamp"
        case eventType = "event_type"
        case eventValue = "event_value"
        case from = "from"
        case url = "url"
        case ref = "ref"
        case recommendationId = "recommendation_id"
        case eventProperties = "event_properties"
        case userProperties = "user_properties"
    }
    
    public init(eventType: String) throws {
        self.eventType = try Validator.validateString(eventType, min: 1, max: 500, varName: "eventType")
    }
    
    @discardableResult
    public func setItemId(_ itemId: String?) throws -> Event {
        self.itemId = try Validator.validateString(itemId, min: 1, max: 500, varName: "itemId")
        return self
    }
    
    @discardableResult
    public func setTimestamp(_ timestamp: Double) throws -> Event {
        self.timestamp = try Validator.validateNumber(timestamp, min: 1648871097, varName: "timestamp")
        return self
    }
    
    @discardableResult
    public func setEventValue(_ eventValue: String?) throws -> Event {
        self.eventValue = try Validator.validateString(eventValue, min: 0, max: 500, varName: "eventValue")
        return self
    }
    
    @discardableResult
    public func setFrom(_ from: String?) throws -> Event {
        self.from = try Validator.validateString(from, min: 1, max: 500, varName: "from")
        return self
    }
    
    @discardableResult
    public func setUrl(_ url: String?) throws -> Event {
        self.url = try Validator.validateString(url, min: 1, varName: "url")
        return self
    }
    
    @discardableResult
    public func setRef(_ ref: String?) throws -> Event {
        self.ref = try Validator.validateString(ref, min: 1, varName: "ref")
        return self
    }
    
    @discardableResult
    public func setRecommendationId(_ recommendationId: String?) throws -> Event {
        self.recommendationId = try Validator.validateString(recommendationId, min: 1, varName: "recommendationId")
        return self
    }
    
    @discardableResult
   public func setEventProperties(_ eventProperties: [String: String]?) -> Event {
        self.eventProperties = eventProperties
        return self
    }
    
    @discardableResult
    public func setUserProperties(_ userProperties: [String: String]?) -> Event {
        self.userProperties = userProperties
        return self
    }
}

extension Event: CustomStringConvertible {
    public var description: String {
        var properties: [String] = []
        
        properties.append("timestamp: \(timestamp)")
        properties.append("eventType: \(eventType)")

        if let bluxId = bluxId {
            if (bluxId != "null") {
                properties.append("bluxId: \(bluxId)")
            }
        }
        if let deviceId = deviceId {
            if (deviceId != "null") {
                properties.append("deviceId: \(deviceId)")
            }
        }
        if let userId = userId {
            if (userId != "null") {
                properties.append("userId: \(userId)")
            }
        }
        if let itemId = itemId {
            if (itemId != "null") {
                properties.append("itemId: \(itemId)")
            }
        }
        if let eventValue = eventValue {
            if (eventValue != "null") {
                properties.append("eventValue: \(eventValue)")
            }
        }
        if let from = from {
            if (from != "null") {
                properties.append("from: \(from)")
            }
        }
        if let url = url {
            if (url != "null") {
                properties.append("url: \(url)")
            }
        }
        if let ref = ref {
            if (ref != "null") {
                properties.append("ref: \(ref)")
            }
        }
        if let recommendationId = recommendationId {
            if (recommendationId != "null") {
                properties.append("recommendationId: \(recommendationId)")
            }
        }
        
        if let eventProperties = eventProperties {
            if eventProperties.count > 0 {
                let eventPropertiesDescription = eventProperties.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                properties.append("eventProperties: [\(eventPropertiesDescription)]")
            }
        }
        
        if let userProperties = userProperties {
            if userProperties.count > 0 {
                let userPropertiesDescription = userProperties.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                properties.append("userProperties: [\(userPropertiesDescription)]")
            }
        }
        
        return "\n\t\(properties.joined(separator: "\n\t"))\n"
    }
}


public class EventResponse: Codable {
    
    public var message: String
    public var failureCount: Int?
    public var timestamp: Double
    public var processedEvents: [Event]?
    public var unprocessedEvents: [Event]?
    
    enum CodingKeys: String,
                     CodingKey {
        case message = "message"
        case failureCount = "failure_count"
        case timestamp = "timestamp"
        case processedEvents = "processed_events"
        case unprocessedEvents = "unprocessed_events"
    }
}

extension EventResponse: CustomStringConvertible {
    public var description: String {
        var properties: [String] = []
        
        properties.append("message: \(message)")
        properties.append("timestamp: \(timestamp)")
        
        if let failureCount = failureCount {
            properties.append("failureCount: \(failureCount)")
        }
        if let processedEvents = processedEvents {
            properties.append("processedEvents: \(processedEvents)")
        }
        if let unprocessedEvents = unprocessedEvents {
            properties.append("unprocessedEvents: \(unprocessedEvents)")
        }
        
        return "\n\(properties.joined(separator: "\n"))"
    }
}
