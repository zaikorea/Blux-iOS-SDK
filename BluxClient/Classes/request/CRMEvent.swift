//
//  CRMEvent.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation

public enum CRMEventType: String {
    case clicked = "open"
    case delivered = "send"
}

public enum CustomerEngagementType: String {
    case campaign
    case flow
    case infotalk
}

open class CRMEvent: Codable {
    
    public var clientId: String? = SdkConfig.clientIdInUserDefaults
    public var eventType: CRMEventType.RawValue
    
    public var bluxId: String? = SdkConfig.bluxIdInUserDefaults
    public var deviceId: String? = SdkConfig.deviceIdInUserDefaults
    public var userId: String? = SdkConfig.userIdInUserDefaults
    public var itemId: String? = nil
    public var eventValue: String? = nil
    public var customerEngagementType: CustomerEngagementType.RawValue
    public var customerEngagementId: String
    public var customerEngagementTaskId: String
    public var eventProperties: [String:String]? = nil
    
    enum CodingKeys: String,
                     CodingKey {
        case clientId = "client_id"
        case eventType = "event_type"
        case bluxId = "blux_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case itemId = "item_id"
        case eventValue = "event_value"
        case customerEngagementType = "customer_engagement_type"
        case customerEngagementId = "customer_engagement_id"
        case customerEngagementTaskId = "customer_engagement_task_id"
        case eventProperties = "event_properties"
    }
    
    public init(
        eventType: CRMEventType,
        itemId: String? = nil,
        customerEngagementType: CustomerEngagementType.RawValue,
        customerEngagementId: String,
        customerEngagementTaskId: String,
        eventProperties: [String:String]? = nil
    ) {
        self.eventType = eventType.rawValue
        self.itemId = itemId
        self.customerEngagementType = customerEngagementType
        self.customerEngagementId = customerEngagementId
        self.customerEngagementTaskId = customerEngagementTaskId
        self.eventProperties = eventProperties
    }
}
