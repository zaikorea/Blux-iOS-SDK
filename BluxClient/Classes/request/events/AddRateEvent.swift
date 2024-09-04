import Foundation

public class AddRateEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "rate"
    
    init(builder: Builder) throws {
        super.init()
        self.events.append(
            try Event(eventType: builder.eventType)
                    .setItemId(builder.itemId)
                    .setEventValue(builder.eventValue)
                    .setEventProperties(builder.eventProperties)
        )
    }
    
    public class Builder {
        var itemId: String
        var eventType: String = AddRateEvent.DEFAULT_EVENT_TYPE
        var eventValue: String
        var eventProperties: [String: String]? = nil
        
        public init(itemId: String, rating: Double) {
            self.itemId = itemId
            self.eventValue = "\(rating)"
        }
        
        public func eventProperties(_ eventProperties: [String: String]) -> Builder {
            self.eventProperties = eventProperties
            return self
        }
        
        public func build() throws -> AddRateEvent {
            return try AddRateEvent(builder: self)
        }
    }
}

