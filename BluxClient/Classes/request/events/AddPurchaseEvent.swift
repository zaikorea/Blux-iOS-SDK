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
        var url: String? = nil
        var ref: String? = nil
        var eventProperties: [String: String]? = nil
        var userProperties: [String: String]? = nil
        
        public init() {
            
        }
        
        public func addPurchase(itemId: String, price: Double, quantity: Int, from: String? = nil, eventProperties: [String: String]? = nil) throws -> Builder {
            guard (quantity > 0) else {
                throw BluxError.InvalidQuantity
            }
            
            let timestamp = Utils.getCurrentUnixTimestamp()
            
            var eventPropertiesWithQuantity = eventProperties ?? [:]
            eventPropertiesWithQuantity["quantity"] = "\(quantity)"
            
            let event = try Event(eventType: eventType)
                .setItemId(itemId)
                .setTimestamp(timestamp)
                .setEventValue("\(price * Double(quantity))")
                .setFrom(from)
                .setUrl(url)
                .setRef(ref)
                .setEventProperties(eventPropertiesWithQuantity)
                .setUserProperties(userProperties)
            
            self.events.append(event)
            return self
        }
        
        public func url(_ url: String) throws -> Builder {
            self.url = url
            for event in events {
                try event.setUrl(url)
            }
            return self
        }
        
        public func ref(_ ref: String) throws -> Builder {
            self.ref = ref
            for event in events {
                try event.setRef(ref)
            }
            return self
        }
        
        public func userProperties(_ userProperties: [String: String]) -> Builder {
            self.userProperties = userProperties
            for event in events {
                event.setUserProperties(userProperties)
            }
            return self
        }
        
        public func build() -> AddPurchaseEvent {
            return AddPurchaseEvent(builder: self)
        }
    }
}

