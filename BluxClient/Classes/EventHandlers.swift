//
//  EventHandlers.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation

final class EventHandlers {
  static var unhandledNotification: BluxNotification?
  static var notificationClicked: ((BluxNotification) -> Void)? = nil
  static var notificationForegroundReceived: ((NotificationReceivedEvent) -> Void)? = nil
}
