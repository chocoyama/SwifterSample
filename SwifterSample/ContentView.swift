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
                Text(server.localhostUrl)
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                UIPasteboard.general.string = self.server.localhostUrl
                            }
                    )
                Text(server.wifiUrl)
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                UIPasteboard.general.string = self.server.wifiUrl
                            }
                    )
            } else {
                Text("Not Running...")
            }
            
            Button(action: {
                self.server.httpServer["/"] = { _ in .ok(.htmlBody(self.buildHtmlBody()))  }
                self.server.start()
            }) {
                Text("Start Server")
            }
            
            Button(action: {
                self.server.httpServer["/"] = { _ in
                    let body = self.buildWebSocketHtml(with: self.server.localAddress,
                                                       port: self.server.port,
                                                       path: "/websocket")
                    return .ok(.htmlBody(body))
                }
                self.server.setUpWebSocket(path: "/websocket")
                self.server.start()
            }) {
                Text("Start Web Socket (Local)")
            }
            
            Button(action: {
                self.server.httpServer["/"] = { _ in
                    let body = self.buildWebSocketHtml(with: self.server.localAddress,
                                                       port: self.server.port,
                                                       path: "/websocket")
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
                self.server.writeWebsocket(text: self.buildHtmlBody())
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
    
    private func buildHtmlBody() -> String {
        let htmlString = readHTML(fileName: "sample")
        let value = "\((100..<20000).randomElement()!)"
        return String(format: htmlString, value)
    }
    
    private func buildWebSocketHtml(with address: String, port: UInt16, path: String?) -> String {
        let htmlString = readHTML(fileName: "websocket")
        let websocketUrl = "ws://\(address):\(port)\(path ?? "")"
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
