//
//  URLSessionProtocol.swift
//  Aura
//
//  Created by Perez William on 11/06/2025.
//

import Foundation

//MARK: Protocole qui définit la seule fonctionnalité de URLSession que les services utilisent :
// la méthode data(for:).
protocol URLSessionProtocol: Sendable {
        func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
