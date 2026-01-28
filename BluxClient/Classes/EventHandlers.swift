import Foundation

/// 인앱 커스텀 액션 핸들러 타입
typealias InAppCustomActionHandler = (_ actionId: String, _ data: [String: Any]) -> Void

enum EventHandlers {
    static var unhandledNotification: BluxNotification?
    static var notificationForegroundWillDisplay: ((NotificationReceivedEvent) -> Void)?
    static var notificationClicked: ((BluxNotification) -> Void)?
    /// Custom HTML 인앱 메시지에서 BluxBridge.triggerAction() 호출 시 실행되는 핸들러 목록
    /// 복수의 핸들러 등록 가능, 등록 순서대로 실행
    static var inAppCustomActionHandlers: [(id: UUID, handler: InAppCustomActionHandler)] = []
}
