//
//  JanusController.swift
//  Runner
//
//  Created by Rafał Adasiewicz on 23/09/2020.
//

import Foundation
import WebRTC

class JanusController {
    
    var isConfigured = false
    private let signalingServer: SimpleWebSocket
    private let webRTCClient: WebRTCClient
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let randomIdGenerator = RandomIdGenerator()
    private let userId: String
    private var connectionEstablishedCompletion: (() -> ())? = nil
    private var nickname: String? = nil
    private var sessionId: Int? = nil
    private var pluginId: Int? = nil
    private var roomId: String? = nil
    private var timer: Timer? = nil
    private var transactions: [String: TransactionType]
    
    
    init(iceServers: [RTCIceServer], signalingServerUrl: String) {
        self.signalingServer = SimpleWebSocket(url: signalingServerUrl)
        self.webRTCClient = WebRTCClient(iceServers: iceServers)
        self.userId = randomIdGenerator.generateAlphaNumeric(length: 10)
        self.transactions = [:]
    }
    
    func connect(connectionEstablishedCompletion: @escaping (() -> ())) {
        self.connectionEstablishedCompletion = connectionEstablishedCompletion
        self.signalingServer.connect(onMessage: { data in
            self.handleMessage(data: data)
        }) {
            self.connectToJanus()
        }
    }
    
    func disconnect() {
        timer?.invalidate()
        if (pluginId != nil) {
            send(data: ["janus" : AnyEncodable(value: "detach")], type: TransactionType.detach)
        }
    }
    
    func joinAndConfigure(room: String, display: String, pin: String, nicknamePrefix: String) {
        self.nickname = display
        webRTCClient.offer(completion: {session in
            self.send(data: ["janus" : AnyEncodable(value: "message"), "body": AnyEncodable(value: JoinBodyEncodable(room: room, display: display + nicknamePrefix, pin: pin)),"jsep": AnyEncodable(value: JoinJsepEncodable(type: "offer", sdp: String(session.sdp)))], type: TransactionType.joinAndConfigure)
        })
    }
    
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        webRTCClient.processSampleBuffer(sampleBuffer)
    }
    
    func processAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        webRTCClient.processAudioBuffer(sampleBuffer)
    }
    
    func leave() {
        send(data: ["janus" : AnyEncodable(value: "message"), "body": AnyEncodable(value: LeaveEncodable())], type: TransactionType.leave)
    }
    
    private func destroy() {
        self.pluginId = nil
        send(data: ["janus" : AnyEncodable(value: "destroy")], type: TransactionType.destroy)
    }
    
    private func disconnectSignalingServer() {
        signalingServer.disconnect()
        isConfigured = false
        timer = nil
        sessionId = nil
        nickname = nil
        roomId = nil
    }
    
    private func connectToJanus() {
        self.send(data: ["janus": AnyEncodable(value: "create")], type: TransactionType.create)
    }
    
    private func keepAlive() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { timer in
            self.send(data: ["janus": AnyEncodable(value: "keepAlive")], type: TransactionType.keepAlive)
        }
    }
    
    private func attachVideoPlugin() {
        self.send(data: ["janus": AnyEncodable(value: "attach"), "plugin": AnyEncodable(value: "janus.plugin.videoroom"),], type: TransactionType.attachVideoPlugin)
    }
    
    private func send(data: [String:AnyEncodable], type: TransactionType) {
        var copyData = data
        let transaction = randomIdGenerator.generateAlpha(length: 10)
        transactions[transaction] = type
        copyData["transaction"] = AnyEncodable(value: transaction)
        copyData["opaque_id"] = AnyEncodable(value: userId)
        if (self.sessionId != nil) {
            copyData["session_id"] = AnyEncodable(value: self.sessionId!)
        }
        if (self.pluginId != nil) {
            copyData["handle_id"] = AnyEncodable(value: self.pluginId!)
        }
        if (type == TransactionType.joinAndConfigure) {
            print("RafalTest \(transaction)")
        }
        
        if let jsonData = try? encoder.encode(copyData) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                signalingServer.send(data: jsonString)
            }
        }
    }
    
    private func handleMessage(data: String) {
        let response = try!decoder.decode(JanusResponse.self, from: data.data(using: .utf8)!)
        if (self.isLeaveMessage(response: response)) {
            self.handleLeave()
            return
        }
        if (response.transaction == nil) {
            print("Skiping message because there is no transaction id")
            return
        }
        if let type = transactions[response.transaction!] {
            if (type != TransactionType.keepAlive && response.janus == "ack") {
                print("Skiping ack message")
                return
            }
            switch type {
            case .create:
                self.sessionId = response.data!.id
                self.attachVideoPlugin()
                break
            case .attachVideoPlugin:
                self.pluginId = response.data!.id
                self.keepAlive()
                self.connectionEstablishedCompletion?()
                self.connectionEstablishedCompletion = nil
                break
            case .keepAlive:
                print("Keeping alive")
                break
            case .joinAndConfigure:
                self.roomId = response.plugindata?.data?.room
                webRTCClient.set(remoteSdp: RTCSessionDescription(type: RTCSdpType.answer, sdp: response.jsep!.sdp), completion:  { (error) in
                    if (error != nil) {
                        print("Setting remoteSDP failed \(String(describing: error))")
                    } else {
                        print("Setting remoteSDP success")
                        
                    }
                })
                isConfigured = true
                break
            case .listParticipants:
                if (self.nickname != nil && response.plugindata?.data?.participants == nil) {
                    self.leave()
                } else {
                    if (!response.plugindata!.data!.participants!.contains(where: {item in
                        return item.display == self.nickname
                    })) {
                        self.leave()
                    }
                }
                break
            case .leave:
                disconnectSignalingServer()
                break
            case .detach:
                self.destroy()
                break
            case .destroy:
                disconnectSignalingServer()
                break
            }
            transactions.removeValue(forKey: response.transaction!)
        } else {
            print("Transaction \(String(describing: response.transaction)) doesn't exist")
        }
    }
    
    private func isLeaveMessage(response: JanusResponse) -> Bool {
        return response.janus == "event" && response.plugindata != nil && response.plugindata?.plugin == "janus.plugin.videoroom" && response.plugindata?.data != nil && response.plugindata?.data?.leaving != nil
    }
    
    private func handleLeave() {
        if (self.roomId != nil) {
            send(data: ["janus" : AnyEncodable(value: "message"), "body": AnyEncodable(value: ListParticipantsEncodable(room: self.roomId!))], type: TransactionType.listParticipants)
        }
    }
}

enum TransactionType {
    case create
    case attachVideoPlugin
    case keepAlive
    case detach
    case destroy
    case joinAndConfigure
    case listParticipants
    case leave
}

struct AnyEncodable: Encodable {
    
    let value: Encodable
    init(value: Encodable) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

struct JoinBodyEncodable: Encodable {
    let request = "joinandconfigure"
    let room: String
    let ptype = "publisher"
    let display: String
    let pin: String
    let audio = true
    let video = true
    let data = false
    let record = false
    
    init(room: String, display: String, pin: String) {
        self.room = room
        self.display = display
        self.pin = pin
    }
}

struct JoinJsepEncodable: Encodable {
    let type: String
    let sdp: String
    
    init(type: String, sdp: String) {
        self.type = type
        self.sdp = sdp
    }
}

struct ListParticipantsEncodable: Encodable {
    let request = "listparticipants"
    let room: String
    
    init(room: String) {
        self.room = room
    }
}

struct LeaveEncodable: Encodable {
    let request = "leave"
}
