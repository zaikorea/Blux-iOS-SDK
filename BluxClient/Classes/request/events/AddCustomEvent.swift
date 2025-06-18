import Foundation

public class AddCustomEvent: EventRequest {
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setItemId(builder.itemId)
                .setOrderId(builder.orderId)
                .setOrderAmount(builder.orderAmount)
                .setPaidAmount(builder.paidAmount)
                .setRating(builder.rating)
                .setPage(builder.page)
                .setItems(builder.items)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }

    public class Builder {
        fileprivate let eventType: String

        fileprivate var itemId: String?
        fileprivate var orderId: String?
        fileprivate var orderAmount: Double?
        fileprivate var paidAmount: Double?
        fileprivate var rating: Double?
        fileprivate var page: String?
        fileprivate var items: [AddOrderEvent.Item] = []
        fileprivate var customEventProperties: [String: CustomEventValue]? = nil

        public init(eventType: String) {
            self.eventType = eventType
        }
        
        public func addItem(id: String, price: Double, quantity: Int) -> Builder {
            self.items.append(AddOrderEvent.Item(id: id, price: price, quantity: quantity))
            return self
        }

        public func itemId(_ itemId: String) -> Builder {
            self.itemId = itemId
            return self
        }
        
        public func orderId(_ orderId: String) -> Builder {
            self.orderId = orderId
            return self
        }

        public func orderAmount(_ amount: Double) -> Builder {
            self.orderAmount = amount
            return self
        }

        public func paidAmount(_ amount: Double) -> Builder {
            self.paidAmount = amount
            return self
        }
        
        public func rating(_ rating: Double) -> Builder {
            self.rating = rating
            return self
        }
        
        public func page(_ page: String) -> Builder {
            self.page = page
            return self
        }

        public func customEventProperties(
            _ customEventProperties: [String: CustomEventValue]
        ) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }

        public func build() throws -> AddCustomEvent {
            return try AddCustomEvent(builder: self)
        }
    }
}
