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
    public var orderAmount: Double?
    public var paidAmount: Double?
    public var items: [AddOrderEvent.Item]?

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
        case orderAmount = "order_amount"
        case paidAmount = "paid_amount"
        case items
    }
}

public enum CustomEventValue: Codable {
    case string(String)
    case double(Double)
    case int(Int)
    case bool(Bool)
    case stringArray([String])

    // Encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .stringArray(let value): try container.encode(value)
        }
    }

    // Decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else {
            throw DecodingError.typeMismatch(
                CustomEventValue.self,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported value")
            )
        }
    }
}

public class Event: Codable {
    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var capturedAt: String
    public var eventType: String
    public var eventProperties: EventProperties
    public var customEventProperties: [String: CustomEventValue]? = nil

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
    public func setItemId(_ itemId: String?) throws -> Event {
        let validatedItemId = try Validator.validateString(itemId, min: 1, max: 500, varName: "itemId")
        eventProperties.itemId = validatedItemId
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
    public func setPage(_ page: String?) throws -> Event {
        if let page = page {
            let validatedPage = try Validator.validateString(page, min: 1, max: 500, varName: "page")
            eventProperties.page = validatedPage
        }
        return self
    }

    @discardableResult
    public func setOrderAmount(_ orderAmount: Double?) throws -> Event {
        if let orderAmount = orderAmount {
            eventProperties.orderAmount = orderAmount
        }
        return self
    }
    
    @discardableResult
    public func setPaidAmount(_ paidAmount: Double?) throws -> Event {
        if let paidAmount = paidAmount {
            eventProperties.paidAmount = paidAmount
        }
        return self
    }
    
    @discardableResult
    public func setItems(_ items: [AddOrderEvent.Item]?) throws -> Event {
        if let items = items {
            eventProperties.items = items
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
    public func setCustomEventProperties(_ customEventProperties: [String: CustomEventValue]?) -> Event {
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
