//
//  JanusResponse.swift
//  Runner
//
//  Created by Rafał Adasiewicz on 24/09/2020.
//

import Foundation

struct JanusResponse: Decodable {
    let janus: String
    let transaction: String?
    let data: JanusData?
    let jsep: JanusJsep?
    let plugindata: JanusPluginData?
}


struct JanusData: Decodable {
    let id: Int
}

struct JanusPluginWithData: Decodable {
    let id: String?
    let leaving: QuantumValue?
    let room: String?
    let participants: [JanusParticipants]?
}

struct JanusJsep: Decodable {
    let type: String
    let sdp: String
}

struct JanusPluginData: Decodable {
    let plugin: String?
    let data: JanusPluginWithData?
}

struct JanusParticipants: Decodable {
    let id: String?
    let display: String?
}

enum QuantumValue: Decodable {
    
    case int(Int), string(String)
    
    init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }
        
        throw QuantumError.missingValue
    }
    
    enum QuantumError:Error {
        case missingValue
    }
}
