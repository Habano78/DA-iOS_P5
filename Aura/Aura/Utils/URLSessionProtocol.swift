//
//  URLSessionProtocol.swift
//  Aura
//
//  Created by Perez William on 11/06/2025.
//

import Foundation

// Ce protocole définit la seule fonctionnalité de URLSession que les services utilisent :
// la méthode data(for:).
protocol URLSessionProtocol {
        func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// On fait en sorte que la vraie classe URLSession d'Apple se conforme à notre protocole.
// Cela nous permet de l'utiliser dans notre code d'application normal sans rien changer.
extension URLSession: URLSessionProtocol {}
