import Foundation

public class AddLikeEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "like"
    
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setItemId(builder.itemId)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        fileprivate let eventType: String = DEFAULT_EVENT_TYPE
        fileprivate let itemId: String
        
        fileprivate var customEventProperties: [String: CustomEventValue]? = nil
        
        public init(itemId: String) {
            self.itemId = itemId
        }
        
        public func customEventProperties(_ customEventProperties: [String: CustomEventValue]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddLikeEvent {
            return try AddLikeEvent(builder: self)
        }
    }
}
