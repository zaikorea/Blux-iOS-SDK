import Foundation

public class AddRateEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "rate"
    
    init(builder: Builder) throws {
        super.init()
        self.events.append(
            try Event(eventType: builder.eventType)
                    .setItemId(builder.itemId)
                    .setRating(builder.rating)
                    .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        var itemId: String
        var eventType: String = AddRateEvent.DEFAULT_EVENT_TYPE
        var rating: Double
        var customEventProperties: [String: String]? = nil
        
        public init(itemId: String, rating: Double) {
            self.itemId = itemId
            self.rating = rating
        }
        
        public func customEventProperties(_ customEventProperties: [String: String]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddRateEvent {
            return try AddRateEvent(builder: self)
        }
    }
}

