import Foundation

public class AddLikeEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "like"
    
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
        var eventType: String = AddLikeEvent.DEFAULT_EVENT_TYPE
        var eventValue: String? = nil
        var eventProperties: [String: String]? = nil
        
        public init(itemId: String) {
            self.itemId = itemId
        }
        
        public func eventValue(_ eventValue: String) -> Builder {
            self.eventValue = eventValue
            return self
        }
        public func eventProperties(_ eventProperties: [String: String]) -> Builder {
            self.eventProperties = eventProperties
            return self
        }
        
        public func build() throws -> AddLikeEvent {
            return try AddLikeEvent(builder: self)
        }
    }
}

