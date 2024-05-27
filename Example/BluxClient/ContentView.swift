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
    
    var body: some View {
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
        }
        .frame(maxWidth: 330)
        .foregroundColor(Color.white)
        .font(.system(size: 20))
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
