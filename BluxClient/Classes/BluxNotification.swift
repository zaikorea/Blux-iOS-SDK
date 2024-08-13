//
//  BluxNotification.swift
//  BluxClient
//
//  Created by Tommy on 5/30/24.
//

import Foundation

@objc open class BluxNotification: NSObject {
    public var id: String
    public var body: String
    public var title: String?
    public var url: String?
    public var imageUrl: String?
    public var data: Dictionary<String, Any>?
    
    public init(id: String, body: String, title: String?, url: String?, imageUrl: String?, data: Dictionary<String, Any>?) {
        self.id = id
        self.body = body
        self.title = title == "" ? nil : title
        self.url = url == "" ? nil : url
        self.imageUrl = imageUrl == "" ? nil : imageUrl
        self.data = data
    }
    
    open override var description: String {
        var properties: [String] = []
        
        properties.append(id)
        properties.append(body)
        properties.append(String(describing: title))
        properties.append(String(describing: url))
        properties.append(String(describing: imageUrl))
        properties.append(String(describing: data))
        
        return "\n\t\(properties.joined(separator: "\n\t"))\n"
    }
    
    static func getBluxNotificationFromUserInfo(userInfo: [AnyHashable: Any]) -> BluxNotification? {
        
        let isBlux = userInfo["isBlux"] as? Bool
        if (isBlux != true) {
            Logger.error("Not a notification from Blux.")
            return nil
        }
        
        guard let aps = userInfo["aps"] as? Dictionary<String, Any>,
              let alert = aps["alert"] as? Dictionary<String, Any>,
              let notificationId = userInfo["notificationId"] as? String,
              let body = alert["body"] as? String else {
            Logger.error("Failed to get BluxNotification: Missing required keys")
            return nil
        }
        
        let notification = BluxNotification(
            id: notificationId,
            body: body,
            title: alert["title"] as? String,
            url: userInfo["url"] as? String,
            imageUrl: userInfo["imageUrl"] as? String,
            data: userInfo["data"] as? Dictionary<String, Any>
        )
        
        return notification
    }
    
    static func getBluxNotificationFromLaunchOptions (launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BluxNotification? {
        guard let userInfo = launchOptions?[.remoteNotification] as? Dictionary<String, Any>, // Check is launched via push notification
              let notification = BluxNotification.getBluxNotificationFromUserInfo(userInfo: userInfo) else {
            return nil
        }
        
        Logger.verbose("Enter app via push notification.")
        
        return notification
    }
    
    public static func getBluxNotificationFromUNNotificationContent(_ notificationContent: UNNotificationContent) -> BluxNotification? {
        guard let bluxNotification = BluxNotification.getBluxNotificationFromUserInfo(userInfo: notificationContent.userInfo) else {
            return nil
        }
        
        return bluxNotification
    }

    public func toDictionary() -> [String: Optional<Any>] {
        let dict: [String: Optional<Any>] = [
            "id": id,
            "body": body,
            "title": title,
            "url": url,
            "imageUrl": imageUrl,
            "data": data
        ]
    
        return dict
  }

}
