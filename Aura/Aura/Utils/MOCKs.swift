//
//  Mocks.swift
//  AuraTests
//
//  Created by Perez William on 08/06/2025.
//

import Foundation
@testable import Aura

//MARK: MockURLSession afin de stocker un Result prédéfini (un succès ou un échec) et de le retourner quand on appelle sa méthode data(for:)
final class MockURLSession: URLSessionProtocol,  @unchecked Sendable {
        
        //MARK: Verrou pour synchroniser l'accès aux propriétés ci-dessous.
        private let lock = NSLock()
        
        //MARK: propriétés privés pour forcer l'accés via le verrou
        // propriétés privées qui stockent réellement les données.
        private var _result: Result<(Data, URLResponse), Error>
        private var _capturedRequest: URLRequest?
        
        
        // Propriétés publiques et "thread-safe" qui utilisent le verrou.
        var result: Result<(Data, URLResponse), Error> {
                get { lock.withLock { _result } }
                set { lock.withLock { _result = newValue } }
        }
        
        var capturedRequest: URLRequest? {
                get { lock.withLock { _capturedRequest } }
                set { lock.withLock { _capturedRequest = newValue } }
        }
        
        init(result: Result<(Data, URLResponse), Error>) {
                self._result = result
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                self.capturedRequest = request
                return try result.get()
        }
}

//MARK: MOCK pour délibérément faire échouer l'encodeur et tester invalidURL
class MockJSONEncoder: JSONEncoderProtocol {
        
        struct MockEncodingError: Error {}
        
        var shouldThrowError = false
        
        func encode<T: Encodable>(_ value: T) throws -> Data {
                if shouldThrowError {
                       
                        throw MockEncodingError()
                }
                /// Si on ne doit pas échouer, on utilise le vrai encodeur pour retourner des données valides.
                return try JSONEncoder().encode(value)
        }
}

//MARK: Ce MOCK nous permet de contrôler entièrement le résultat de l'appel à login() pendant les tests, sans faire de vrais appels réseau.
class MockAuthService: AuthenticationServiceProtocol {
        
        var loginResult: Result<UserSession, any Error>
        
        // Propriétés espions
        var loginCallCount = 0
        var receivedCredentials: AuthRequestDTO?
        
        // Init pour définir le comportement du mock pour un test donné.
        init(result: Result<UserSession, any Error>) {
                self.loginResult = result
        }
        
        func login(credentials: AuthRequestDTO) async throws -> UserSession {
                loginCallCount += 1
                receivedCredentials = credentials
                return try loginResult.get()
        }
}

// Ce nous permet de contrôler le résultat de l'appel à getAccountDetails().
class MockAccountService: AccountServiceProtocol {
        
        var getDetailsResult: Result<AccountDetails, any Error>
        
        // Propriétés espions
        var getDetailsCallCount = 0
        var receivedUserSession: UserSession?
        
        init(result: Result<AccountDetails, any Error>) {
                self.getDetailsResult = result
        }
        
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails {
                getDetailsCallCount += 1
                receivedUserSession = identifiant
                return try getDetailsResult.get()
        }
}

//MARK: Ce MOck nous permet de contrôler le résultat de l'appel à sendMoney().
class MockTransferService: TransferServiceProtocol {

        var sendMoneyResult: Result<Void, any Error> /// Pour le succès, le type est Void, car la méthode ne retourne rien.
        
        //Propriétés espions
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
                return try sendMoneyResult.get()
        }
}
