//
//  EventHandlers.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation

enum EventHandlers {
    static var unhandledNotification: BluxNotification?
    static var notificationClicked: ((BluxNotification) -> Void)?
    static var notificationForegroundReceived: ((NotificationReceivedEvent) -> Void)?
}
