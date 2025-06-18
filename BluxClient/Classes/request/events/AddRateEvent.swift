import Foundation

public class AddRateEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "rate"
    
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setItemId(builder.itemId)
                .setRating(builder.rating)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        fileprivate let eventType: String = DEFAULT_EVENT_TYPE
        fileprivate let itemId: String
        fileprivate let rating: Double
        
        fileprivate var customEventProperties: [String: CustomEventValue]? = nil
        
        public init(itemId: String, rating: Double) {
            self.itemId = itemId
            self.rating = rating
        }
        
        public func customEventProperties(_ customEventProperties: [String: CustomEventValue]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddRateEvent {
            return try AddRateEvent(builder: self)
        }
    }
}
