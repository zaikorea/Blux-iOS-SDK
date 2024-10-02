import Foundation

public class AddRecommendationViewEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "recommendation_view"
    
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
        var itemId: String? = nil
        var eventType: String = AddRecommendationViewEvent.DEFAULT_EVENT_TYPE
        var eventValue: String? = nil
        var eventProperties: [String: String]? = nil
        
        public init() {
        }
        
        public func itemId(_ itemId: String) -> Builder {
            self.itemId = itemId
            return self
        }
        
        public func eventValue(_ eventValue: String) -> Builder {
            self.eventValue = eventValue
            return self
        }
        public func eventProperties(_ eventProperties: [String: String]) -> Builder {
            self.eventProperties = eventProperties
            return self
        }
        
        public func build() throws -> AddRecommendationViewEvent {
            return try AddRecommendationViewEvent(builder: self)
        }
    }
}

