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

//MARK: Ce MOCK(fausse version d'AuthService) nous permet de contrôler entièrement le résultat de l'appel à login() pendant les tests, sans faire de vrais appels réseau.
class MockAuthService: AuthenticationServiceProtocol {
        
        // On peut configurer ce mock pour qu'il retourne un succès ou une erreur.
        var loginResult: Result<UserSession, any Error>
        
        /// Ces propriétés "espions" nous permettent de vérifier si et comment la méthode a été appelée.
        var loginCallCount = 0
        var receivedCredentials: AuthRequestDTO?
        
        // Initialiseur pour définir le comportement du mock pour un test donné.
        init(result: Result<UserSession, any Error>) {
                self.loginResult = result
        }
        
        func login(credentials: AuthRequestDTO) async throws -> UserSession {
                // Quand la méthode login est appelée :
                loginCallCount += 1               // On incrémente le compteur d'appels.
                receivedCredentials = credentials // On sauvegarde les credentials reçus pour vérification.
                
                // On retourne le résultat prédéfini (soit le UserSession, soit l'erreur).
                return try loginResult.get()
        }
}

// MARK: Ce nous permet de contrôler le résultat de l'appel à getAccountDetails().
class MockAccountService: AccountServiceProtocol {
        
        /// On peut configurer ce mock pour qu'il retourne un succès ou une erreur.
        var getDetailsResult: Result<AccountDetails, any Error>
        
        /// Ces propriétés "espions" nous permettent de vérifier si et comment la méthode a été appelée.
        var getDetailsCallCount = 0
        var receivedUserSession: UserSession?
        
        init(result: Result<AccountDetails, any Error>) {
                self.getDetailsResult = result
        }
        
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails {
                /// Quand la méthode getDetails est appelée :
                getDetailsCallCount += 1               // On incrémente le compteur d'appels.
                receivedUserSession = identifiant // On sauvegarde les credentials reçus pour vérification.// Retourne le résultat prédéfini.
                return try getDetailsResult.get()
        }
}

//MARK: Ce MOck nous permet de contrôler le résultat de l'appel à sendMoney().
class MockTransferService: TransferServiceProtocol {
        
        /// On peut configurer ce mock pour qu'il retourne un succès ou une erreur.
        /// Pour le succès, le type est Void, car la méthode ne retourne rien.
        var sendMoneyResult: Result<Void, any Error>
        
        // "Espions" pour vérifier les interactions
        private(set) var sendMoneyCallCount = 0
        private(set) var receivedTransferData: TransferRequestData?
        private(set) var receivedUserSession: UserSession?
        
        init(result: Result<Void, any Error>) {
                self.sendMoneyResult = result
        }
        
        func sendMoney(transferData: TransferRequestData, identifiant: UserSession) async throws {
                sendMoneyCallCount += 1
                receivedTransferData = transferData
                receivedUserSession = identifiant
                return try sendMoneyResult.get() /// .get() sur un Result<Void, Error> ne retourne rien si c'est un succès,  ou lance l'erreur si c'est un échec.
        }
}
