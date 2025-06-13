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

//MARK: pour tester invalidURL nous devons délibérément faire échouer l'encodeur.
class MockJSONEncoder: JSONEncoderProtocol {
    
    struct MockEncodingError: Error {}
    
    // Si 'shouldThrowError' est true, la méthode encode lancera une erreur.
    var shouldThrowError = false

    func encode<T: Encodable>(_ value: T) throws -> Data {
        if shouldThrowError {
            // On lance notre erreur définie ci-dessus.
            throw MockEncodingError()
        }
        // Si on ne doit pas échouer, on utilise le vrai encodeur pour retourner des données valides.
        return try JSONEncoder().encode(value)
    }
}
