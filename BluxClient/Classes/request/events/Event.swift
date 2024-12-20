import Foundation

public class EventProperties: Codable {
    public var itemId: String?
    public var section: String?
    public var prevSection: String?
    public var recommendationId: String?
    public var price: Double?
    public var orderId: String?
    public var rating: Double?
    public var prevPage: String?
    public var page: String?
    public var position: Double?

    enum CodingKeys: String,
        CodingKey
    {
        case itemId = "item_id"
        case section
        case prevSection = "prev_section"
        case recommendationId = "recommendation_id"
        case price
        case orderId = "order_id"
        case rating
        case prevPage = "prev_page"
        case page
        case position
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
    public func setSection(_ section: String?) throws -> Event {
        if let section = section {
            let validatedSection = try Validator.validateString(section, min: 1, max: 500, varName: "section")
            eventProperties.section = validatedSection
        }
        return self
    }

    @discardableResult
    public func setPrevSection(_ prevSection: String?) throws -> Event {
        if let prevSection = prevSection {
            let validatedPrevSection = try Validator.validateString(prevSection, min: 1, max: 500, varName: "prevSection")
            eventProperties.prevSection = validatedPrevSection
        }
        return self
    }

    @discardableResult
    public func setRecommendationId(_ recommendationId: String?) throws -> Event {
        if let recommendationId = recommendationId {
            let validatedRecommendationId = try Validator.validateString(recommendationId, min: 1, max: 500, varName: "recommendationId")
            eventProperties.recommendationId = validatedRecommendationId
        }
        return self
    }

    @discardableResult
    public func setPrice(_ price: Double?) throws -> Event {
        if let price = price {
            let validatedPrice = try Validator.validateNumber(price, min: 0, varName: "price")
            eventProperties.price = validatedPrice
        }
        return self
    }

    @discardableResult
    public func setOrderId(_ orderId: String?) throws -> Event {
        if let orderId = orderId {
            let validatedOrderId = try Validator.validateString(orderId, min: 1, max: 500, varName: "orderId")
            eventProperties.orderId = validatedOrderId
        }
        return self
    }

    @discardableResult
    public func setRating(_ rating: Double?) throws -> Event {
        if let rating = rating {
            eventProperties.rating = rating
        }
        return self
    }

    @discardableResult
    public func setPrevPage(_ prevPage: String?) throws -> Event {
        if let prevPage = prevPage {
            let validatedPrevPage = try Validator.validateString(prevPage, min: 1, max: 500, varName: "prevPage")
            eventProperties.prevPage = validatedPrevPage
        }
        return self
    }

    @discardableResult
    public func setPage(_ page: String?) throws -> Event {
        if let page = page {
            let validatedPage = try Validator.validateString(page, min: 1, max: 500, varName: "page")
            eventProperties.page = validatedPage
        }
        return self
    }

    @discardableResult
    public func setPosition(_ position: Double?) throws -> Event {
        if let position = position {
            eventProperties.position = position
        }
        return self
    }

    @discardableResult
    public func setEventProperties(_ eventProperties: EventProperties?) -> Event {
        if let eventProperties = eventProperties {
            self.eventProperties = eventProperties
        }
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
