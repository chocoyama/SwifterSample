//
//  ContentView.swift
//  SwifterSample
//
//  Created by Takuya Yokoyama on 2020/04/02.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI
import Swifter

struct ContentView: View {
    private let server = HttpServer()
    private let port: UInt16 = 8080
    private var localhostUrl: String { "http://\(localAddress):\(String(port))" }
    private var wifiUrl: String { "http://\(wifiAddress!):\(String(port))" }
    private var localAddress: String { "127.0.0.1" }
    private var wifiAddress: String? {
        var address : String?
        
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                //            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    @State private var listening = false
    @State private var session: WebSocketSession?
    
    var body: some View {
        VStack(spacing: 16) {
            if listening {
                Text(localhostUrl)
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                UIPasteboard.general.string = self.localhostUrl
                            }
                    )
                Text(wifiUrl)
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                UIPasteboard.general.string = self.wifiUrl
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
                self.stopServer()
            }) {
                Text("Stop Server")
            }
            
            Button(action: {
                self.session?.writeText(self.buildHtmlBody())
            }) {
                Text("Send")
            }
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
        server["/"] = { _ in .ok(.htmlBody(self.buildHtmlBody()))  }
        startServer()
    }
    
    private func startLocalWebSocket() {
        server["/"] = { _ in .ok(.htmlBody(self.buildWebSocketHtml(with: self.localAddress)))  }
        startWebSocket()
        startServer()
    }
    
    private func startWifiWebSocket() {
        server["/"] = { _ in .ok(.htmlBody(self.buildWebSocketHtml(with: self.wifiAddress!)))  }
        startWebSocket()
        startServer()
    }
    
    private func startWebSocket() {
        server["/websocket"] = websocket(text: { session, text in
            self.session = session
            session.writeText(text)
        }, binary: { session, binary in
            self.session = session
            session.writeBinary(binary)
        })
    }
    
    private func startServer() {
        do {
            try server.start(port, forceIPv4: false)
            listening = true
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    private func stopServer() {
        server.stop()
        listening = false
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
