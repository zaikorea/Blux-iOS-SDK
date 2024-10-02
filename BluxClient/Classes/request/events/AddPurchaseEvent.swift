import Foundation

public class AddPurchaseEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "purchase"
    
    init(builder: Builder) {
        super.init()
        self.events.append(contentsOf: builder.events)
    }
    
    public class Builder {
        var events: [Event] = []
        var eventType: String = AddPurchaseEvent.DEFAULT_EVENT_TYPE
        var eventProperties: [String: String]? = nil
        
        public init() {
            
        }
        
        public func addPurchase(itemId: String, price: Double, quantity: Int, eventProperties: [String: String]? = nil) throws -> Builder {
            guard (quantity > 0) else {
                throw BluxError.InvalidQuantity
            }
            
            var eventPropertiesWithQuantity = eventProperties ?? [:]
            eventPropertiesWithQuantity["quantity"] = "\(quantity)"
            
            let event = try Event(eventType: eventType)
                .setItemId(itemId)
                .setEventValue("\(price * Double(quantity))")
                .setEventProperties(eventPropertiesWithQuantity)
            
            self.events.append(event)
            return self
        }
        
        public func build() -> AddPurchaseEvent {
            return AddPurchaseEvent(builder: self)
        }
    }
}

