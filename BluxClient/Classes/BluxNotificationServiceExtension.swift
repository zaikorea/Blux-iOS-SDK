//
//  BluxNotificationServiceExtension.swift
//  BluxClient
//
//  Created by Tommy on 6/4/24.
//

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
    
    // A closure for delivering mutated notification content to the system
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    @objc public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            guard let bluxNotification = BluxNotification.getBluxNotificationFromUNNotificationContent(request.content) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            EventService.createReceived(bluxNotification.id)

            guard let imageUrl = bluxNotification.imageUrl,
                  let attachmentUrl = URL(string: imageUrl)
            else {
                contentHandler(bestAttemptContent)
                return
            }
            
            // Download image from imageUrl and attach to the notification
            let task = URLSession.shared.downloadTask(with: attachmentUrl) { downloadedUrl, _, error in
                if let _ = error {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                if let downloadedUrl = downloadedUrl, let attachment = try? UNNotificationAttachment(identifier: "Blux_notification_attachment", url: downloadedUrl, options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]) {
                    bestAttemptContent.attachments = [attachment]
                }
                
                contentHandler(bestAttemptContent)
            }
            
            task.resume()
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
}
