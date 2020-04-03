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
    private let httpServer = HTTPServer(port: 8080)
    private let websocketServer = WebSocketServer(port: 8080)
    @State private var listening = false
    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack(spacing: 16) {
            if listening {
                CopyableText(httpServer.url(mode: .localhost))
                CopyableText(httpServer.url(mode: .lan))
            } else {
                Text("Not Running...")
            }
            
            if !listening {
                Button(action: {
                    self.httpServer.httpServer["/"] = { _ in
                        let value = "\((100..<20000).randomElement()!)"
                        let text = String(format: HTML.read(fileName: "sample")!, value)
                        return .ok(.htmlBody(text))
                    }
                    self.httpServer.start()
                }) {
                    Text("Start Server")
                }
                
                Button(action: {
                    self.websocketServer.setUp(clientPath: "/", serverPath: "/websocket", mode: .localhost)
                    self.websocketServer.start()
                }) {
                    Text("Start Web Socket (Local)")
                }
                
                Button(action: {
                    self.websocketServer.setUp(clientPath: "/", serverPath: "/websocket", mode: .lan)
                    self.websocketServer.start()
                }) {
                    Text("Start Web Socket (Wi-Fi)")
                }
            } else {
                Button(action: {
                    let value = "\((100..<20000).randomElement()!)"
                    let text = String(format: HTML.read(fileName: "sample")!, value, "hoge")
                    self.websocketServer.writeTextToClient(text)
                }) {
                    Text("Send")
                }
            }
            
            if listening {
                Button(action: {
                    self.httpServer.stop()
                    self.websocketServer.stop()
                }) {
                    Text("Stop Server")
                }
            }
        }.onAppear {
            self.httpServer.listening
                .assign(to: \.listening, on: self)
                .store(in: &self.cancellables)
            self.websocketServer.listening
                .assign(to: \.listening, on: self)
                .store(in: &self.cancellables)
        }.onDisappear {
            self.cancellables.forEach { $0.cancel() }
        }
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
