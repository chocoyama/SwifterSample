//
//  ContentView.swift
//  SwifterSample
//
//  Created by Takuya Yokoyama on 2020/04/02.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI
import Swifter
import Combine

struct ContentView: View {
    private let server = Server(port: 8080)
    @State private var listening = false
    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack(spacing: 16) {
            if listening {
                CopyableText(server.localhostUrl(scheme: "http"))
                CopyableText(server.lanUrl(scheme: "http"))
            } else {
                Text("Not Running...")
            }
            
            Button(action: {
                self.server.httpServer["/"] = { _ in
                    .ok(.htmlBody(self.buildHtmlBody(value: "\((100..<20000).randomElement()!)")))
                }
                self.server.start()
            }) {
                Text("Start Server")
            }
            
            Button(action: {
                self.server.httpServer["/"] = { _ in
                    let websocketUrl = "\(self.server.localhostUrl(scheme: "ws"))/websocket"
                    let body = self.buildWebSocketHtml(websocketUrl: websocketUrl)
                    return .ok(.htmlBody(body))
                }
                self.server.setUpWebSocket(path: "/websocket")
                self.server.start()
            }) {
                Text("Start Web Socket (Local)")
            }
            
            Button(action: {
                self.server.httpServer["/"] = { _ in
                    let websocketUrl = "\(self.server.lanUrl(scheme: "ws"))/websocket"
                    let body = self.buildWebSocketHtml(websocketUrl: websocketUrl)
                    return .ok(.htmlBody(body))
                }
                self.server.setUpWebSocket(path: "/websocket")
                self.server.start()
            }) {
                Text("Start Web Socket (Wi-Fi)")
            }
            
            Button(action: {
                self.server.stop()
            }) {
                Text("Stop Server")
            }
            
            Button(action: {
                let text = self.buildHtmlBody(value: "\((100..<20000).randomElement()!)")
                self.server.writeWebsocket(text: text)
            }) {
                Text("Send")
            }
        }.onAppear {
            self.server.listening
                .assign(to: \.listening, on: self)
                .store(in: &self.cancellables)
        }.onDisappear {
            self.cancellables.forEach { $0.cancel() }
        }
    }
    
    private func buildHtmlBody(value: String) -> String {
        let htmlString = readHTML(fileName: "sample")
        return String(format: htmlString, value)
    }
    
    private func buildWebSocketHtml(websocketUrl: String) -> String {
        let htmlString = readHTML(fileName: "websocket")
        return String(format: htmlString, websocketUrl)
    }
    
    private func readHTML(fileName: String) -> String {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "html")!)
        let htmlData = try! Data(contentsOf: url)
        let htmlString = String(data: htmlData, encoding: .utf8)!
        return htmlString
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CopyableText: View {
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .gesture(
                LongPressGesture()
                    .onEnded { _ in
                        UIPasteboard.general.string = self.text
                    }
            )
    }
}
