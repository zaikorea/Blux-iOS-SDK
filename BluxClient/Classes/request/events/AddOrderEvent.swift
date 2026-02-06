import Foundation

public class AddOrderEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "order"

    init(builder: Builder) throws {
        super.init()

        try events.append(
            Event(eventType: Self.DEFAULT_EVENT_TYPE)
                .setOrderId(builder.orderId)
                .setOrderAmount(builder.orderAmount)
                .setPaidAmount(builder.paidAmount)
                .setItems(builder.items)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }

    public class Item: Codable {
        public var id: String
        public var price: Double
        public var quantity: Int
        public var customEventProperties: [String: CustomEventValue]?

        enum CodingKeys: String, CodingKey {
            case id
            case price
            case quantity
            case customEventProperties = "custom_event_properties"
        }

        init(id: String, price: Double, quantity: Int, customEventProperties: [String: CustomEventValue]? = nil) {
            self.id = id
            self.price = price
            self.quantity = quantity
            self.customEventProperties = customEventProperties
        }
    }

    public class Builder {
        fileprivate var orderId: String?
        fileprivate var orderAmount: Double?
        fileprivate var paidAmount: Double?
        fileprivate var customEventProperties: [String: CustomEventValue]?
        fileprivate var items: [Item] = []

        public init() {}

        public func addItem(id: String, price: Double, quantity: Int, customEventProperties: [String: CustomEventValue]? = nil) -> Builder {
            items.append(Item(id: id, price: price, quantity: quantity, customEventProperties: customEventProperties))
            return self
        }

        public func orderId(_ orderId: String) -> Builder {
            self.orderId = orderId
            return self
        }

        public func orderAmount(_ amount: Double) -> Builder {
            orderAmount = amount
            return self
        }

        public func paidAmount(_ amount: Double) -> Builder {
            paidAmount = amount
            return self
        }

        public func customEventProperties(_ properties: [String: CustomEventValue]) -> Builder {
            customEventProperties = properties
            return self
        }

        public func build() throws -> AddOrderEvent {
            return try AddOrderEvent(builder: self)
        }
    }
}
