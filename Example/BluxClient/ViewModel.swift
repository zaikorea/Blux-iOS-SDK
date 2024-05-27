//
//  ViewModel.swift
//  BluxClient_Example
//
//  Created by Tommy on 5/24/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Combine
import BluxClient

class ViewModel: ObservableObject {
    let itemId1 = "ITEM_ID_1"
    let itemId2 = "ITEM_ID_2"
    let from = "homepage"
    @Published var eventRequests: [String:EventRequest] = [:]

    init() {
        generateEventRequests()
    }

    func generateEventRequests() {
        do {
            /// Cartadd
            let addCartaddEvent = try AddCartaddEvent.Builder(itemId: itemId1).build()
            self.eventRequests["CartAdd"] = addCartaddEvent
            
            /// PDV
            let addProductDetailViewEvent = try AddProductDetailViewEvent.Builder(itemId: itemId1).build()
            self.eventRequests["PDV"] = addProductDetailViewEvent
            
            /// Like
            let addLikeEvent = try AddLikeEvent.Builder(itemId: itemId1).build()
            self.eventRequests["Like"] = addLikeEvent
            
            /// PageView
            let addPageViewEvent = try AddPageViewEvent.Builder(from: from).build()
            self.eventRequests["PageView"] = addPageViewEvent
            
            /// RecView
            let addRecommendationViewEvent = try AddRecommendationViewEvent.Builder(from: from)
                                                                            .userProperties(["KEY1": "VALUE1", "KEY2": "VALUE2"])
                                                                            .build()
            self.eventRequests["RecView"] = addRecommendationViewEvent
            
            /// Purchase
            let addPurchaseEvent = try AddPurchaseEvent.Builder()
                                            .addPurchase(itemId: itemId1, price: 3000, quantity: 1)
                                            .addPurchase(itemId: itemId2, price: 1000, quantity: 5)
                                            .build()
            self.eventRequests["Purchase"] = addPurchaseEvent
            
            /// Search
            let addSearchEvent = try AddSearchEvent.Builder(searchQuery: "검색어").build()
            self.eventRequests["Search"] = addSearchEvent
            
            /// Rate
            let addRateEvent = try AddRateEvent.Builder(itemId: itemId1, rating: 4.8).build()
            self.eventRequests["Rate"] = addRateEvent
            
            
        } catch let error {
            /// Request 생성 실패 시 에러 메시지 출력
            print(error.localizedDescription)
        }
    }
}
