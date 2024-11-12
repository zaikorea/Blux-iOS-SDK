import Foundation

public class Event: Codable {

    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var itemId: String? = nil
    public var capturedAt: String
    public var eventType: String
    public var eventValue: String? = nil
    public var eventProperties: [String: String]? = nil

    enum CodingKeys: String,
        CodingKey
    {
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case itemId = "item_id"
        case capturedAt = "captured_at"
        case eventType = "event_type"
        case eventValue = "event_value"
        case eventProperties = "event_properties"
    }

    public init(eventType: String) {
        let dateFormatter = ISO8601DateFormatter()
        self.capturedAt = dateFormatter.string(from: Date())
        self.eventType = eventType
    }

    @discardableResult
    public func setItemId(_ itemId: String?) throws -> Event {
        self.itemId = try Validator.validateString(
            itemId, min: 1, max: 500, varName: "itemId")
        return self
    }

    @discardableResult
    public func setEventValue(_ eventValue: String?) throws -> Event {
        self.eventValue = try Validator.validateString(
            eventValue, min: 0, max: 500, varName: "eventValue")
        return self
    }

    @discardableResult
    public func setEventProperties(_ eventProperties: [String: String]?)
        -> Event
    {
        self.eventProperties = eventProperties
        return self
    }
}

extension Event: CustomStringConvertible {
    public var description: String {
        var properties: [String] = []

        properties.append("capturedAt: \(capturedAt)")
        properties.append("eventType: \(eventType)")

        if let bluxId = bluxId {
            if bluxId != "null" {
                properties.append("bluxId: \(bluxId)")
            }
        }
        if let deviceId = deviceId {
            if deviceId != "null" {
                properties.append("deviceId: \(deviceId)")
            }
        }
        if let userId = userId {
            if userId != "null" {
                properties.append("userId: \(userId)")
            }
        }
        if let itemId = itemId {
            if itemId != "null" {
                properties.append("itemId: \(itemId)")
            }
        }
        if let eventValue = eventValue {
            if eventValue != "null" {
                properties.append("eventValue: \(eventValue)")
            }
        }

        if let eventProperties = eventProperties {
            if eventProperties.count > 0 {
                let eventPropertiesDescription = eventProperties.map {
                    "\($0.key): \($0.value)"
                }.joined(separator: ", ")
                properties.append(
                    "eventProperties: [\(eventPropertiesDescription)]")
            }
        }

        return "\n\t\(properties.joined(separator: "\n\t"))\n"
    }
}

public class EventResponse: Codable {

    public var message: String
    public var failureCount: Int?
    public var capturedAt: String
    public var processedEvents: [Event]?
    public var unprocessedEvents: [Event]?

    enum CodingKeys: String,
        CodingKey
    {
        case message = "message"
        case failureCount = "failure_count"
        case capturedAt = "capturedAt"
        case processedEvents = "processed_events"
        case unprocessedEvents = "unprocessed_events"
    }
}

extension EventResponse: CustomStringConvertible {
    public var description: String {
        var properties: [String] = []

        properties.append("message: \(message)")
        properties.append("capturedAt: \(capturedAt)")

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
