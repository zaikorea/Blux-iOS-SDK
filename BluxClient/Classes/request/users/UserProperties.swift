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

    public init(phoneNumber: String? = nil, emailAddress: String? = nil) {
        self.phoneNumber = phoneNumber
        self.emailAddress = emailAddress
    }
    
    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case emailAddress = "email_address"
    }
}
