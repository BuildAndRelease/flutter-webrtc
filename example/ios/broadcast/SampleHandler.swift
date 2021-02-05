//
//  SampleHandler.swift
//  broadcast
//
//  Created by Rafał Adasiewicz on 22/09/2020.
//

import ReplayKit
import WebRTC

class SampleHandler: RPBroadcastSampleHandler {
    
    private static let suiteName = "group.leancode.screensharing"
    
    private let janusController = JanusController(iceServers: [
        RTCIceServer(urlStrings: ["stun:rtc.tensafe.net:3478"]), RTCIceServer(urlStrings: ["turn:rtc.tensafe.net:3478"], username: "test", credential: "123456")], signalingServerUrl: "wss://rtc.tensafe.net:8989")
    
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        #if DEBUG
        RTCSetMinDebugLogLevel(RTCLoggingSeverity.verbose)
        #endif
        
        let userDefaults = UserDefaults.init(suiteName: SampleHandler.suiteName)
        
        let nickname = userDefaults?.string(forKey: "nickname")
        let roomId = userDefaults?.string(forKey: "roomId")
        let roomSecret = userDefaults?.string(forKey: "roomSecret")
        
        if (nickname == nil || roomId == nil || roomSecret == nil) {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "You can only broadcast from ScreenShare App"]
            
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -1, userInfo: userInfo))
        } else {
            janusController.connect() {
                self.janusController.joinAndConfigure(room: roomId!, display: nickname!, pin: roomSecret!, nicknamePrefix: "ScreenShare")
            }
        }
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        janusController.leave()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            if (janusController.isConfigured) {
                janusController.processSampleBuffer(sampleBuffer)
            }
            break
        case RPSampleBufferType.audioApp:
            if (janusController.isConfigured) {
                janusController.processAudioBuffer(sampleBuffer)
            }
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}
