//
//  MockURLSession.swift
//  AuraTests
//
//  Created by Perez William on 08/06/2025.
//

import Foundation
@testable import Aura

//MARK: Le rôle de MockURLSession est de stocker un Result prédéfini (un succès ou un échec) et de le retourner quand on appelle sa méthode data(for:)
final class MockURLSession: URLSessionProtocol,  @unchecked Sendable {
        
        // Verrou pour synchroniser l'accès aux propriétés ci-dessous.
        private let lock = NSLock()
        
        //MARK: propriétés privés pour forcer l'accés via le verrou
        // Les propriétés privées qui stockent réellement les données.
            private var _result: Result<(Data, URLResponse), Error> /// On configure le résultat que l'on veut simuler
            private var _capturedRequest: URLRequest? /// On ajoute une variable pour capturer la requête
        
        
        // Propriétés publiques et "thread-safe" qui utilisent le verrou.
            var result: Result<(Data, URLResponse), Error> {
                get { lock.withLock { _result } }
                set { lock.withLock { _result = newValue } }
            }
        
        // 'capturedRequest' est maintenant accessible en lecture et en écriture
            // depuis le test, mais son accès est toujours protégé par le verrou.
            var capturedRequest: URLRequest? {
                get { lock.withLock { _capturedRequest } }
                set { lock.withLock { _capturedRequest = newValue } }
            }
            
        init(result: Result<(Data, URLResponse), Error>) {
                self._result = result
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                // Quand la méthode est appelée, on capture la requête...
                self.capturedRequest = request
                // ...et on retourne le résultat prédéfini.
                return try result.get()
        }
}

//MARK: MOCK pour tester invalidURL nous devons délibérément faire échouer l'encodeur.
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





