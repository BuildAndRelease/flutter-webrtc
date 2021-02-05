//
//  RandomIdGenerator.swift
//  Runner
//
//  Created by Rafał Adasiewicz on 23/09/2020.
//

import Foundation

class RandomIdGenerator {
    private let alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private let alphaNumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    
    func generateAlphaNumeric(length: Int) -> String {
        return String((0..<length).map{ _ in alphaNumeric.randomElement()! })
    }
    
    func generateAlpha(length: Int) -> String {
        return String((0..<length).map{ _ in alpha.randomElement()! })
    }
}
