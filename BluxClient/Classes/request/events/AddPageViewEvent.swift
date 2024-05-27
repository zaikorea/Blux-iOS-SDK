import Foundation

public class AddPageViewEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "page_view"
    
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
        var itemId: String? = nil
        var timestamp: Double = Utils.getCurrentUnixTimestamp()
        var eventType: String = AddPageViewEvent.DEFAULT_EVENT_TYPE
        var eventValue: String? = nil
        var from: String
        var url: String? = nil
        var ref: String? = nil
        var recommendationId: String? = nil
        var eventProperties: [String: String]? = nil
        var userProperties: [String: String]? = nil
        
        public init(from: String) {
            self.from = from
        }
        
        public func itemId(_ itemId: String) -> Builder {
            self.itemId = itemId
            return self
        }
        
        public func timestamp(_ timestamp: Double) -> Builder {
            self.timestamp = timestamp
            return self
        }
        
        public func eventValue(_ eventValue: String) -> Builder {
            self.eventValue = eventValue
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
        
        public func build() throws -> AddPageViewEvent {
            return try AddPageViewEvent(builder: self)
        }
    }
}

