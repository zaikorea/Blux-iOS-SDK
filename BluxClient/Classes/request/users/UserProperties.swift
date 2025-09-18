//
//  UserProperties.swift
//  BluxClient
//
//  Created by 이경원 on 2024/08/05.
//

import Foundation

public class UserProperties: Codable {
    var phoneNumber: String?
    var emailAddress: String?
    var marketingNotificationConsent: Bool?
    var marketingNotificationSmsConsent: Bool?
    var marketingNotificationEmailConsent: Bool?
    var marketingNotificationPushConsent: Bool?
    var marketingNotificationKakaoConsent: Bool?
    

    public init(phoneNumber: String? = nil, emailAddress: String? = nil, marketingNotificationConsent: Bool? = nil, marketingNotificationSmsConsent: Bool? = nil, marketingNotificationEmailConsent: Bool? = nil, marketingNotificationPushConsent: Bool? = nil, marketingNotificationKakaoConsent: Bool? = nil) {
        self.phoneNumber = phoneNumber
        self.emailAddress = emailAddress
        self.marketingNotificationConsent = marketingNotificationConsent
        self.marketingNotificationSmsConsent = marketingNotificationSmsConsent
        self.marketingNotificationEmailConsent = marketingNotificationEmailConsent
        self.marketingNotificationPushConsent = marketingNotificationPushConsent
        self.marketingNotificationKakaoConsent = marketingNotificationKakaoConsent
    }
    
    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case emailAddress = "email_address"
        case marketingNotificationConsent = "marketing_notification_consent"
        case marketingNotificationSmsConsent = "marketing_notification_sms_consent"
        case marketingNotificationEmailConsent = "marketing_notification_email_consent"
        case marketingNotificationPushConsent = "marketing_notification_push_consent"
        case marketingNotificationKakaoConsent = "marketing_notification_kakao_consent"
    }
}
