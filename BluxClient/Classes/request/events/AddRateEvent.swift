import Foundation

public class AddRateEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "rate"
    
    init(builder: Builder) throws {
        super.init()
        self.events.append(
            try Event(eventType: builder.eventType)
                    .setItemId(builder.itemId)
                    .setTimestamp(builder.timestamp)
                    .setEventValue(builder.eventValue)
                    .setFrom(builder.from)
                    .setUrl(builder.url)
                    .setRef(builder.ref)
                    .setRecommendationId(builder.recommendationId)
                    .setEventProperties(builder.eventProperties)
                    .setUserProperties(builder.userProperties)
        )
    }
    
    public class Builder {
        var itemId: String
        var timestamp: Double = Utils.getCurrentUnixTimestamp()
        var eventType: String = AddRateEvent.DEFAULT_EVENT_TYPE
        var eventValue: String
        var from: String? = nil
        var url: String? = nil
        var ref: String? = nil
        var recommendationId: String? = nil
        var eventProperties: [String: String]? = nil
        var userProperties: [String: String]? = nil
        
        public init(itemId: String, rating: Double) {
            self.itemId = itemId
            self.eventValue = "\(rating)"
        }
        
        public func timestamp(_ timestamp: Double) -> Builder {
            self.timestamp = timestamp
            return self
        }
        
        public func from(_ from: String) -> Builder {
            self.from = from
            return self
        }
        
        public func url(_ url: String) -> Builder {
            self.url = url
            return self
        }
        
        public func ref(_ ref: String) -> Builder {
            self.ref = ref
            return self
        }
        
        public func recommendationId(_ recommendationId: String) -> Builder {
            self.recommendationId = recommendationId
            return self
        }
        
        public func eventProperties(_ eventProperties: [String: String]) -> Builder {
            self.eventProperties = eventProperties
            return self
        }
        
        public func userProperties(_ userProperties: [String: String]) -> Builder {
            self.userProperties = userProperties
            return self
        }
        
        public func build() throws -> AddRateEvent {
            return try AddRateEvent(builder: self)
        }
    }
}

