import Foundation

public class EventProperties: Codable {
    public var itemId: String?
    public var price: Double?
    public var rating: Double?
    public var page: String?

    enum CodingKeys: String,
        CodingKey
    {
        case itemId = "item_id"
        case price
        case rating
        case page
    }
}

public class Event: Codable {
    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var capturedAt: String
    public var eventType: String
    public var eventProperties: EventProperties
    public var customEventProperties: [String: String]? = nil

    enum CodingKeys: String,
        CodingKey
    {
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case capturedAt = "captured_at"
        case eventType = "event_type"
        case eventProperties = "event_properties"
        case customEventProperties = "custom_event_properties"
    }

    public init(eventType: String) {
        let dateFormatter = ISO8601DateFormatter()
        self.capturedAt = dateFormatter.string(from: Date())
        self.eventType = eventType
        self.eventProperties = EventProperties()
    }

    @discardableResult
    public func setItemId(_ itemId: String) throws -> Event {
        let validatedItemId = try Validator.validateString(itemId, min: 1, max: 500, varName: "itemId")
        eventProperties.itemId = validatedItemId
        return self
    }

    @discardableResult
    public func setPage(_ page: String) throws -> Event {
        let validatedPage = try Validator.validateString(page, min: 1, max: 500, varName: "page")

        eventProperties.page = validatedPage
        return self
    }

    @discardableResult
    public func setPrice(_ price: Double) throws -> Event {
        let validatedPrice = try Validator.validateNumber(price, min: 0, varName: "price")
        eventProperties.price = validatedPrice
        return self
    }

    @discardableResult
    public func setRating(_ rating: Double) throws -> Event {
        let validatedRating = try Validator.validateNumber(rating, min: 0, varName: "rating")
        eventProperties.rating = validatedRating
        return self
    }

    @discardableResult
    public func setCustomEventProperties(_ customEventProperties: [String: String]?) -> Event {
        self.customEventProperties = customEventProperties
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

        if let customEventProperties = customEventProperties {
            if customEventProperties.count > 0 {
                let customEventPropertiesDescription = customEventProperties.map {
                    "\($0.key): \($0.value)"
                }.joined(separator: ", ")
                properties.append(
                    "customEventProperties: [\(customEventPropertiesDescription)]"
                )
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
        case message
        case failureCount = "failure_count"
        case capturedAt
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
