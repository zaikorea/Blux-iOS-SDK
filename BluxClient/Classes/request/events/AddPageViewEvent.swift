import Foundation

public class AddPageViewEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "page_view"
    
    init(builder: Builder) throws {
        super.init()
        self.events.append(
            try Event(eventType: builder.eventType)
                    .setPage(builder.page)
                    .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        var eventType: String = AddPageViewEvent.DEFAULT_EVENT_TYPE
        var page: String
        var customEventProperties: [String: String]? = nil
        
        public init(page: String) {
            self.page = page
        }
        

        public func customEventProperties(_ customEventProperties: [String: String]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddPageViewEvent {
            return try AddPageViewEvent(builder: self)
        }
    }
}

