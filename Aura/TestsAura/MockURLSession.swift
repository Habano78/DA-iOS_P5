//
//  MockURLSession.swift
//  AuraTests
//
//  Created by Perez William on 08/06/2025.
//

import Foundation
@testable import Aura

//MARK: Le rôle de MockURLSession est de stocker un Result prédéfini (un succès ou un échec) et de le retourner quand on appelle sa méthode data(for:)
class MockURLSession: URLSessionProtocol {
        
        // On configure le résultat que l'on veut simuler
        var result: Result<(Data, URLResponse), Error>
        // On ajoute une variable pour capturer la requête
        var capturedRequest: URLRequest?
        
        init(result: Result<(Data, URLResponse), Error>) {
                self.result = result
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                // Quand la méthode est appelée, on capture la requête...
                self.capturedRequest = request
                // ...et on retourne le résultat prédéfini.
                return try result.get()
        }
}
