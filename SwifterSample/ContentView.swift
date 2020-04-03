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
                CopyableText(server.url(scheme: "http", mode: .localhost))
                CopyableText(server.url(scheme: "http", mode: .lan))
            } else {
                Text("Not Running...")
            }
            
            if !listening {
                Button(action: {
                    self.server.httpServer["/"] = { _ in
                        let value = "\((100..<20000).randomElement()!)"
                        let text = String(format: HTML.read(fileName: "sample"), value)
                        return .ok(.htmlBody(text))
                    }
                    self.server.start()
                }) {
                    Text("Start Server")
                }
                
                Button(action: {
                    self.server.setUpWebSocket(clientPath: "/", serverPath: "/websocket", mode: .localhost)
                    self.server.start()
                }) {
                    Text("Start Web Socket (Local)")
                }
                
                Button(action: {
                    self.server.setUpWebSocket(clientPath: "/", serverPath: "/websocket", mode: .lan)
                    self.server.start()
                }) {
                    Text("Start Web Socket (Wi-Fi)")
                }
            } else {
                Button(action: {
                    let value = "\((100..<20000).randomElement()!)"
                    let text = String(format: HTML.read(fileName: "sample"), value)
                    self.server.writeWebsocket(text: text)
                }) {
                    Text("Send")
                }
            }
            
            if listening {
                Button(action: {
                    self.server.stop()
                }) {
                    Text("Stop Server")
                }
            }
        }.onAppear {
            self.server.listening
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
