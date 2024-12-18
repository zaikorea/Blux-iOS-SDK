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
        fileprivate let eventType: String

        fileprivate var itemId: String?
        fileprivate var customEventProperties: [String: String]? = nil

        public init(eventType: String) {
            self.eventType = eventType
        }

        public func itemId(_ itemId: String) -> Builder {
            self.itemId = itemId
            return self
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
