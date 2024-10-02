import Foundation

public class AddCustomEvent: EventRequest {
    
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
        var itemId: String?
        var eventType: String
        var eventValue: String? = nil
        var eventProperties: [String: String]? = nil
        
        public init(eventType: String) {
            self.eventType = eventType
        }
        
        public func eventValue(_ eventValue: String) -> Builder {
            self.eventValue = eventValue
            return self
        }
        
        public func eventProperties(_ eventProperties: [String: String]) -> Builder {
            self.eventProperties = eventProperties
            return self
        }
        
        public func build() throws -> AddCustomEvent {
            return try AddCustomEvent(builder: self)
        }
    }
}

