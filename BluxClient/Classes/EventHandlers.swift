import Foundation

enum EventHandlers {
    static var unhandledNotification: BluxNotification?
    static var notificationForegroundWillDisplay: ((NotificationReceivedEvent) -> Void)?
    static var notificationClicked: ((BluxNotification) -> Void)?
    /// Custom HTML 인앱 메시지에서 BluxBridge.triggerAction() 호출 시 실행되는 핸들러
    /// - Parameters:
    ///   - actionId: 액션 식별자 (예: "share", "navigate", "custom_event")
    ///   - data: 액션과 함께 전달된 데이터 (Dictionary)
    static var inAppCustomAction: ((_ actionId: String, _ data: [String: Any]) -> Void)?
}
