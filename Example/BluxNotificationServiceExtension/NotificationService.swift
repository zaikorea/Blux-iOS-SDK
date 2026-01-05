import BluxClient

// Swizzling Disabled
class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Logger.verbose(request.content.userInfo)
        if BluxNotificationServiceExtensionHelper.shared.isBluxNotification(request) {
            BluxNotificationServiceExtensionHelper.shared.didReceive(request, withContentHandler: contentHandler)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        BluxNotificationServiceExtensionHelper.shared.serviceExtensionTimeWillExpire()
    }
}
