import Intents
import MobileCoreServices
import UIKit
import UserNotifications

open class BluxNotificationServiceExtension: UNNotificationServiceExtension {
    override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        BluxNotificationServiceExtensionHelper.shared.didReceive(request, withContentHandler: contentHandler)
    }

    override open func serviceExtensionTimeWillExpire() {
        BluxNotificationServiceExtensionHelper.shared.serviceExtensionTimeWillExpire()
    }
}

@objc public class BluxNotificationServiceExtensionHelper: NSObject {
    @objc public static let shared = BluxNotificationServiceExtensionHelper()

    private static let imageDownloadTimeout: TimeInterval = 10

    // A closure for delivering mutated notification content to the system
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    @objc public func didReceive(_ request: UNNotificationRequest,
                                 withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void,
                                 interceptor: BluxNotificationInterceptor? = nil)
    {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let bluxNotification = BluxNotification.getBluxNotificationFromUNNotificationContent(bestAttemptContent)

        interceptor?(request, bestAttemptContent, bluxNotification)

        guard let bluxNotification = bluxNotification else {
            contentHandler(bestAttemptContent)
            return
        }

        bluxNotification.trackReceived()

        guard let imageUrl = bluxNotification.imageUrl,
              let attachmentUrl = URL(string: imageUrl)
        else {
            contentHandler(bestAttemptContent)
            return
        }

        attachImage(from: attachmentUrl, to: bestAttemptContent) {
            contentHandler(bestAttemptContent)
        }
    }

    // Called just before when the extension is terminated by the system
    @objc public func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    @objc public func isBluxNotification(_ request: UNNotificationRequest) -> Bool {
        if let _ = BluxNotification.getBluxNotificationFromUNNotificationContent(request.content) {
            return true
        }

        return false
    }

    private func attachImage(from url: URL, to content: UNMutableNotificationContent, completion: @escaping () -> Void) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.imageDownloadTimeout
        config.timeoutIntervalForResource = Self.imageDownloadTimeout
        let session = URLSession(configuration: config)

        let task = session.downloadTask(with: url) { downloadedUrl, _, error in
            defer { completion() }

            if error != nil { return }
            guard let downloadedUrl = downloadedUrl else { return }

            // URLSession 임시 파일은 completion handler return 후 시스템이 삭제 가능하므로,
            // contentHandler 호출 시점까지 살아남는 stable URL로 옮긴 뒤 attachment를 만든다.
            let stableUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            do {
                try FileManager.default.moveItem(at: downloadedUrl, to: stableUrl)
            } catch {
                return
            }

            if let attachment = try? UNNotificationAttachment(
                identifier: "Blux_notification_attachment",
                url: stableUrl,
                options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]
            ) {
                content.attachments = [attachment]
            } else {
                // attachment 생성 실패면 시스템이 file을 own하지 않으므로 직접 정리.
                try? FileManager.default.removeItem(at: stableUrl)
            }
        }
        task.resume()
    }
}

public typealias BluxNotificationInterceptor = (
    _ request: UNNotificationRequest,
    _ content: UNMutableNotificationContent,
    _ bluxNotification: BluxNotification?
) -> Void
