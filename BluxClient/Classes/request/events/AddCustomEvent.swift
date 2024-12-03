import Foundation

public class AddCustomEvent: EventRequest {
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setItemId(builder.itemId ?? "")
                .setCustomEventProperties(builder.customEventProperties)
        )
    }

    public class Builder {
        var itemId: String?
        var eventType: String
        var customEventProperties: [String: String]? = nil

        public init(eventType: String) {
            self.eventType = eventType
        }

        public func customEventProperties(
            _ customEventProperties: [String: String]
        ) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }

        public func build() throws -> AddCustomEvent {
            return try AddCustomEvent(builder: self)
        }
    }
}
