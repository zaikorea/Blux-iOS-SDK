import Foundation

enum EventHandlers {
    static var unhandledNotification: BluxNotification?
    static var notificationForegroundWillDisplay: ((NotificationReceivedEvent) -> Void)?
    static var notificationClicked: ((BluxNotification) -> Void)?
    
}
