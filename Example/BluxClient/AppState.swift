//
//  AppState.swift
//  BluxNotificationServiceExtenstion
//
//  Created by Tommy on 6/19/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI

class AppState: ObservableObject {
    enum Tab: Int {
        case home = 0
        case test
        case popular
        case cart
    }

    @Published var selectedTab: Tab = .home
    @Published var selectedProductId: String? = nil
}

