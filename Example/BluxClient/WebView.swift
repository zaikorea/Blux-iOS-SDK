//
//  WebView.swift
//  Blux
//
//  Created by Tommy on 5/17/24.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var url = ""
    
    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: url) else {
            return WKWebView()
        }
        let webView = WKWebView()
        
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        guard let url = URL(string: url) else { return }
        
        webView.load(URLRequest(url: url))
    }
}

#Preview {
    WebView()
}
