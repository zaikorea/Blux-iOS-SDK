//
//  ContentView.swift
//  BluxClient_Example
//
//  Created by Tommy on 5/21/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI
import BluxClient

struct ContentView: View {
    @State var userId: String = ""
    @StateObject private var viewModel = ViewModel()
    var eventTypes: [String] = ["PDV", "RecView", "Purchase", "CartAdd", "Like", "PageView", "Rate", "Search"]
    @EnvironmentObject var appState: AppState
    @State private var isWebViewPresented = false
    @State private var webViewURL: String?
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house")
                }.tag(AppState.Tab.home)
            
            
            ScrollView {
                VStack(spacing: 40) {
                    HStack {
                        TextField("User ID", text: $userId)
                            .font(.system(size: 20))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(lineWidth: 2)
                            )
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                        
                        Button {
                            /// Set User ID
                            BluxClient.setUserId(userId: userId.count > 0 ? userId : nil)
                        } label: {
                            Text("Set User ID")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal)
                    
                    HStack(spacing: 30) {
                        Button {
                            BluxClient.subscribe()
                        } label: {
                            Text("Subscribe")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                                .frame(width: 130)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        
                        Button {
                            BluxClient.unsubscribe()
                        } label: {
                            Text("Unsubscribe")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                                .frame(width: 130)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    HStack(spacing: 30) {
                        Button {
                            /// Set log level to verbose
                            BluxClient.setLogLevel(level: .verbose)
                        } label: {
                            Text("VERBOSE")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        Button {
                            /// Set log level to error
                            BluxClient.setLogLevel(level: .error)
                        } label: {
                            Text("ERROR")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        Button {
                            /// Set log level to none
                            BluxClient.setLogLevel(level: .none)
                        } label: {
                            Text("NONE")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    ForEach(eventTypes, id: \.self) { eventType in
                        let eventRequest = viewModel.eventRequests[eventType]
                        BluxEventRequestButton(eventRequest: eventRequest, eventType: eventType)
                    }
                }
            }
            .onAppear {
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    //                resetUserDefaults()
                }
            }.tabItem {
                Label("테스트", systemImage: "gamecontroller")
            }
            .tag(AppState.Tab.test)
            
            
            PopularView()
                .tabItem {
                    Label("인기", systemImage: "flame")
                }.tag(AppState.Tab.popular)
            
            CartView()
                .tabItem {
                    Label("장바구니", systemImage: "cart")
                }.tag(AppState.Tab.cart)
            
        }
        .onChange(of: appState.selectedProductId) { productId in
            if let productId = productId {
                webViewURL = "https://www.musinsa.com/app/goods/\(productId)"
                isWebViewPresented = true
                appState.selectedProductId = nil
            }
        }
        .sheet(isPresented: $isWebViewPresented) {
            if let webViewURL = webViewURL {
                WebView(url: webViewURL)
            }
        }
    }
}

struct BluxEventRequestButton: View {
    let eventRequest: EventRequest?
    let eventType: String
    
    var body: some View {
        Button {
            guard let eventRequest = self.eventRequest else {
                print("No \(eventType) request.")
                return
            }
            // sendRequest는 에러를 내부적으로 처리하므로 throw하지 않음
            BluxClient.sendRequest(eventRequest)
        } label: {
            Text("Send \(eventType)")
                .font(.title)
                .frame(maxWidth: 330)
        }
        .foregroundColor(Color.white)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor)
        )
    }
}

func resetUserDefaults() {
    let defaults = UserDefaults.standard
    defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    defaults.synchronize()
}

#Preview {
    ContentView()
}
