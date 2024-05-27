//
//  AppDelegate.swift
//  BluxClient
//
//  Created by dongjoocha on 05/21/2024.
//  Copyright (c) 2024 dongjoocha. All rights reserved.
//

import UIKit
import SwiftUI
import BluxClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let clientId = "test"
    let secretKey = "KVPzvdHTPWnt0xaEGc2ix-eqPXFCdEV5zcqolBr_h1k"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        let contentView = ContentView()
        BluxClient.initialize(launchOptions, bluxClientId: clientId, bluxSecretKey: secretKey)

        // Create the SwiftUI view that provides the window contents.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }
}
