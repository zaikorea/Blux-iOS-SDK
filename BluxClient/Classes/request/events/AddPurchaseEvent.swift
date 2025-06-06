import Foundation

public class AddPurchaseEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "purchase"
    
    init(builder: Builder) {
        super.init()
        self.events.append(contentsOf: builder.events)
    }
    
    public class Builder {
        fileprivate var events: [Event] = []
        
        public init() {}
        
        public func addPurchase(itemId: String, price: Double, quantity: Int, orderId: String? = nil, customEventProperties: [String: String]? = nil) throws -> Builder {
            guard quantity > 0 else {
                throw BluxError.InvalidQuantity
            }
            
            var customEventPropertiesWithQuantity = customEventProperties ?? [:]
            customEventPropertiesWithQuantity["quantity"] = "\(quantity)"
            
            let event = try Event(eventType: DEFAULT_EVENT_TYPE)
                .setItemId(itemId)
                .setPrice(price * Double(quantity))
                .setOrderId(orderId)
                .setCustomEventProperties(customEventPropertiesWithQuantity)
            
            self.events.append(event)
            return self
        }
        
        public func build() -> AddPurchaseEvent {
            return AddPurchaseEvent(builder: self)
        }
    }
}
