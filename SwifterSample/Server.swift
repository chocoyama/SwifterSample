//
//  Server.swift
//  SwifterSample
//
//  Created by Takuya Yokoyama on 2020/04/03.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import Foundation
import Swifter
import Combine

class Server {
    enum Mode {
        case localhost
        case lan
    }
    
    let port: UInt16
    let httpServer = HttpServer()
    let listening = CurrentValueSubject<Bool, Never>(false)
    
    init(port: UInt16) {
        self.port = port
    }
    
    func url(scheme: String, mode: Mode) -> String {
        switch mode {
        case .localhost: return "\(scheme)://127.0.0.1:\(String(port))"
        case .lan: return "\(scheme)://\(Wifi.address(for: .v4)!):\(String(port))"
        }
    }
    
    func start() {
        do {
            try httpServer.start(port, forceIPv4: false)
            listening.send(true)
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    func stop() {
        httpServer.stop()
        listening.send(false)
    }
}

class HTTPServer: Server {
    func url(mode: Mode) -> String {
        url(scheme: "http", mode: mode)
    }
}

class WebSocketServer: Server {
    private var session: WebSocketSession?
    
    func url(mode: Mode) -> String {
        url(scheme: "ws", mode: mode)
    }
    
    func setUp(clientPath: String, serverPath: String, mode: Mode) {
        httpServer[clientPath] = { _ in
            let websocketUrl = "\(self.url(mode: mode))\(serverPath)"
            let htmlString = String(format: HTML.read(fileName: "websocket"), websocketUrl)
            return .ok(.htmlBody(htmlString))
        }
        
        httpServer[serverPath] = websocket(text: { session, text in
            self.session = session
            session.writeText(text)
        }, binary: { session, binary in
            self.session = session
            session.writeBinary(binary)
        })
    }
    
    func write(text: String) {
        self.session?.writeText(text)
    }
}

struct Wifi {
    enum IP {
        case v4
        case v6
        
        var addrFamily: UInt8 {
            switch self {
            case .v4: return UInt8(AF_INET)
            case .v6: return UInt8(AF_INET6)
            }
        }
    }
    
    static func address(for ip: IP) -> String? {
        var address : String?
        
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        
        sequence(first: firstAddr, next: { $0.pointee.ifa_next })
            .map { $0.pointee }
            .filter {
                $0.ifa_addr.pointee.sa_family == ip.addrFamily
                    && String(cString: $0.ifa_name) == "en0"
            }
            .forEach {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo($0.ifa_addr,
                            socklen_t($0.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            socklen_t(0),
                            NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        
        freeifaddrs(ifaddr)
        
        return address
    }
}

struct HTML {
    static func read(fileName: String) -> String {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "html")!)
        let htmlData = try! Data(contentsOf: url)
        let htmlString = String(data: htmlData, encoding: .utf8)!
        return htmlString
    }
}
