import Foundation

public class AddLikeEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "like"
    
    init(builder: Builder) throws {
        super.init()
        self.events.append(
            try Event(eventType: builder.eventType)
                .setItemId(builder.itemId)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        var itemId: String
        var eventType: String = AddLikeEvent.DEFAULT_EVENT_TYPE
        var customEventProperties: [String: String]? = nil
        
        public init(itemId: String) {
            self.itemId = itemId
        }
        
        public func customEventProperties(_ customEventProperties: [String: String]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddLikeEvent {
            return try AddLikeEvent(builder: self)
        }
    }
}

