import BluxClient

// Swizzling Disabled
class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Logger.verbose(request.content.userInfo)

        if BluxNotificationServiceExtensionHelper.shared.isBluxNotification(request) {
            BluxNotificationServiceExtensionHelper.shared.didReceive(request, withContentHandler: contentHandler)
        } else {
            // 다른 푸시 공급자를 사용한다면 다음 줄 대신 해당 공급자 handler에 위임한다.
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        BluxNotificationServiceExtensionHelper.shared.serviceExtensionTimeWillExpire()
    }
}
