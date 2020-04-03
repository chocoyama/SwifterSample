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
    enum Network {
        case ipv4
        case ipv6
        
        var addrFamily: UInt8 {
            switch self {
            case .ipv4: return UInt8(AF_INET)
            case .ipv6: return UInt8(AF_INET6)
            }
        }
    }
    
    let port: UInt16
    let httpServer = HttpServer()
    let listening = CurrentValueSubject<Bool, Never>(false)
    private var session: WebSocketSession?
    
    init(port: UInt16) {
        self.port = port
    }
    
    func localhostUrl(scheme: String) -> String {
        "\(scheme)://127.0.0.1:\(String(port))"
    }
    
    func lanUrl(scheme: String) -> String {
        "\(scheme)://\(wifiAddress(for: .ipv4)!):\(String(port))"
    }
    
    func setUpWebSocket(path: String) {
        httpServer[path] = websocket(text: { session, text in
            self.session = session
            session.writeText(text)
        }, binary: { session, binary in
            self.session = session
            session.writeBinary(binary)
        })
    }
    
    func writeWebsocket(text: String) {
        self.session?.writeText(text)
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
    
    private func wifiAddress(for network: Network) -> String? {
        var address : String?
        
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == network.addrFamily {
                if String(cString: interface.ifa_name) == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil,
                                socklen_t(0),
                                NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
}
