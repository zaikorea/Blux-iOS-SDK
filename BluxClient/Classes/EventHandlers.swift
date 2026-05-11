import Foundation

/// 인앱 커스텀 액션 핸들러 타입
typealias InAppCustomActionHandler = (_ actionId: String, _ data: [String: Any]) -> Void

enum EventHandlers {
    static var unhandledNotification: BluxNotification?
    static var notificationForegroundWillDisplay: ((NotificationReceivedEvent) -> Void)?
    static var notificationClicked: ((BluxNotification) -> Void)?
    /// 인앱 메시지의 http/https 링크 클릭 시 호출되는 핸들러 (banner link, fullscreen link 대상).
    /// 등록되어 있으면 SDK는 URL 자동 오픈을 수행하지 않고 콜백만 호출한다.
    /// Custom HTML의 data-blux-click(inapp_opened)에는 영향이 없다.
    static var inAppClicked: ((BluxInApp) -> Void)?
    /// Custom HTML 인앱 메시지에서 BluxBridge.triggerAction() 호출 시 실행되는 핸들러 목록
    /// 복수의 핸들러 등록 가능, 등록 순서대로 실행
    static var inAppCustomActionHandlers: [(id: UUID, handler: InAppCustomActionHandler)] = []
}
