//
//  SimpleWebSocket.swift
//  Runner
//
//  Created by Rafał Adasiewicz on 23/09/2020.
//

import Foundation
import Starscream

class SimpleWebSocket: WebSocketDelegate {
    private var socket: WebSocket?
    var isConnected = false
    
    private let url: String
    private var onMessage: ((String) -> ())? = nil
    
    private var connectCompletion: (() -> ())? = nil
    
    init(url: String) {
        self.url = url
        self.socket = nil
    }
    
    func connect(onMessage: @escaping (String) -> (), completion: @escaping () -> ()) {
        self.onMessage = onMessage
        self.connectCompletion = completion
        var request = URLRequest(url: URL(string: self.url)!)
        request.timeoutInterval = 5
        request.addValue("janus-protocol", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        self.socket = WebSocket(request: request)
        self.socket!.delegate = self
        self.socket!.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        print(event)
        switch event {
        case .connected(let headers):
            isConnected = true
            self.connectCompletion!()
            self.connectCompletion = nil
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            self.onMessage?(string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error( _):
            isConnected = false
        }
    }
    
    func send(data: String) {
        self.socket!.write(string: data)
    }
}
