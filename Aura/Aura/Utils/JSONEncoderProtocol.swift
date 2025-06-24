//
//  JSONEncoderProtocol.swift
//  AuraTests
//
//  Created by Perez William on 13/06/2025.
// Pour tester le cas requestEncodingFailed

import Foundation

//MARK: Protocole qui définit le contrat pour tout objet capable d'encoder.
protocol JSONEncoderProtocol {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

// On fait conformer la vraie classe JSONEncoder d'Apple à notre protocole.
// Cela nous permet de l'utiliser par défaut dans notre application.
extension JSONEncoder: JSONEncoderProtocol {}
