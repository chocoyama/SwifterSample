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
    private let server = Server()
    private let port: UInt16 = 8080
    @State private var listening = false
    @State private var session: WebSocketSession?
    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack(spacing: 16) {
            if listening {
                Text(server.localhostUrl(port: port))
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                UIPasteboard.general.string = self.server.localhostUrl(port: self.port)
                            }
                    )
                Text(server.wifiUrl(port: port))
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                UIPasteboard.general.string = self.server.wifiUrl(port: self.port)
                            }
                    )
            } else {
                Text("Not Running...")
            }
            
            Button(action: {
                self.startHTTP()
            }) {
                Text("Start Server")
            }
            
            Button(action: {
                self.startLocalWebSocket()
            }) {
                Text("Start Web Socket (Local)")
            }
            
            Button(action: {
                self.startWifiWebSocket()
            }) {
                Text("Start Web Socket (Wi-Fi)")
            }
            
            Button(action: {
                self.server.stop()
            }) {
                Text("Stop Server")
            }
            
            Button(action: {
                self.session?.writeText(self.buildHtmlBody())
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
    
    private func buildHtmlBody(shouldPolling: Bool = false) -> String {
        let value = "\((100..<20000).randomElement()!)"
        if shouldPolling {
            return """
            <script>
            function doReloadNoCache() {
                window.location.reload(true);
            }
            window.addEventListener('load', function () {
                setTimeout(doReloadNoCache, 2000);
            });
            </script>
            <p style="font-size: 200px;">\(value)</p>
            """
        } else {
            return """
            <p style="font-size: 200px;">\(value)</p>
            """
        }
    }
    
    private func buildWebSocketHtml(with address: String) -> String {
        """
        <!DOCTYPE html>
        <meta charset="utf-8" />
        <script language="javascript" type="text/javascript">

        var wsUri = "ws://\(address):\(port)/websocket";
        var output;

        function init()
        {
          output = document.getElementById("output");
          testWebSocket();
        }

        function testWebSocket()
        {
          websocket = new WebSocket(wsUri);
          websocket.onopen = function(evt) { onOpen(evt) };
          websocket.onclose = function(evt) { onClose(evt) };
          websocket.onmessage = function(evt) { onMessage(evt) };
          websocket.onerror = function(evt) { onError(evt) };
        }

        function onOpen(evt)
        {
          writeToScreen("CONNECTED");
          doSend("CONNECTED");
        }

        function onClose(evt)
        {
          writeToScreen("DISCONNECTED");
        }

        function onMessage(evt)
        {
          output.innerHTML = evt.data;
          // writeToScreen('<span style="color: blue;">RESPONSE: ' + evt.data+'</span>');
        }

        function onError(evt)
        {
          writeToScreen('<span style="color: red;">ERROR:</span> ' + evt.data);
        }

        function doSend(message)
        {
          // writeToScreen("SENT: " + message);
          websocket.send(message);
        }

        function writeToScreen(message)
        {
          var pre = document.createElement("p");
          pre.style.wordWrap = "break-word";
          pre.innerHTML = message;
          output.appendChild(pre);
        }

        window.addEventListener("load", init, false);

        </script>

        <div id="output"></div>
        """
    }
    
    private func startHTTP() {
        server.httpServer["/"] = { _ in .ok(.htmlBody(self.buildHtmlBody()))  }
        server.start(port: port)
    }
    
    private func startLocalWebSocket() {
        server.httpServer["/"] = { _ in .ok(.htmlBody(self.buildWebSocketHtml(with: self.server.localAddress)))  }
        startWebSocket()
        server.start(port: port)
    }
    
    private func startWifiWebSocket() {
        server.httpServer["/"] = { _ in .ok(.htmlBody(self.buildWebSocketHtml(with: self.server.wifiAddress(for: .ipv4)!)))  }
        startWebSocket()
        server.start(port: port)
    }
    
    private func startWebSocket() {
        server.httpServer["/websocket"] = websocket(text: { session, text in
            self.session = session
            session.writeText(text)
        }, binary: { session, binary in
            self.session = session
            session.writeBinary(binary)
        })
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
