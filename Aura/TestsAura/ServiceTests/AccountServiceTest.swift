//
//  AccountServiceTest.swift
//  AuraTests
//
//  Created by Perez William on 08/06/2025.
//

import Testing
@testable import Aura
import Foundation

@Suite(.serialized)
struct AccountServiceTests {
        private let accountURL = URL(string: "http://127.0.0.1:8080/account")!
        private let testToken = "un-token-pour-le-test"
        
        @Test("getAccountDetails en cas de succès retourne les AccountDetails mappés")
        func test_getAccountDetails_onSuccess_returnsCorrectData() async throws {
                // --- ARRANGE ---
                let dto = AccountDetailsDTO(currentBalance: 123.45, transactions: [TransactionDTO(value: -10, label: "Test")])
                let jsonData = try! JSONEncoder().encode(dto)
                let httpResponse = HTTPURLResponse(url: accountURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let successResult: Result<(Data, URLResponse), Error> = .success((jsonData, httpResponse))
                let mockUrlSession = MockURLSession(result: successResult)
                let accountService = AccountService(urlSession: mockUrlSession)
                
                // --- ACT ---
                let result = try await accountService.getAccountDetails(identifiant: UserSession(token: testToken))
                
                // --- ASSERT ---
                #expect(result.totalAmount == dto.currentBalance)
                #expect(result.transactions.count == 1)
                #expect(result.transactions.first?.label == "Test")
        }
        
        @Test("getAccountDetails avec un token invalide lance l'erreur .tokenInvalidOrExpired")
        func test_getAccountDetails_onInvalidToken_throwsError() async throws {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: accountURL, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let accountService = AccountService(urlSession: mockUrlSession)
                
                // --- ACT & ASSERT ---
                do {
                        _ = try await accountService.getAccountDetails(identifiant: UserSession(token: "invalid"))
                        Issue.record("getAccountDetails() aurait dû lancer une erreur.")
                } catch let error as APIServiceError {
                        #expect(error == .tokenInvalidOrExpired)
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
        
        @Test("Cas où le serveur (500) lance l'erreur .unexpectedStatusCode")
        func test_getAccountDetails_onServerError_throwsUnexpectedStatusCodeError() async throws {
                // --- ARRANGE: configuration du Mock pour retourner statu 500 ---
                let httpResponse = HTTPURLResponse(url: accountURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let accountService = AccountService(urlSession: mockUrlSession) ///instance d'AccountService
                
                // --- ACT & ASSERT ---
                let dummyUserSession = UserSession(token: "any-token")
                do { /// On appelle  la méthode a tester
                        _ = try await accountService.getAccountDetails(identifiant: dummyUserSession)
                        Issue.record("La fonction getAccountDetails() aurait dû lancer une erreur, mais elle a réussi.")
                        
                }catch let error as APIServiceError{
                        #expect(error == .unexpectedStatusCode(500))
                }
                catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
        
        @Test("Test le serveur envoi des donnes corrompues")
        func test_getAccountDetails_onBadJSONResponse_throwsDecodingFailedError() async throws {
                // ARRANGE
                let invalidJsonString = """
                {
                    "balance": 123.45,
                    "transactions": []
                }
                """
                let invalidJSONData = invalidJsonString.data(using: .utf8)!
                let httpResponse = HTTPURLResponse(url: accountURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let badDataSuccessResult: Result<(Data, URLResponse), Error> = .success((invalidJSONData, httpResponse))
                let mockUrlSession = MockURLSession(result: badDataSuccessResult)
                /// On crée le service à tester en lui injectant notre mock.
                let accountService = AccountService(urlSession: mockUrlSession)
                
                // ACT & ASSERT
                let dummyUserSession = UserSession(token: "any-token")
                do {
                        _ = try await accountService.getAccountDetails(identifiant: dummyUserSession)
                        Issue.record("La fonction getAccountDetails() aurait dû lancer une erreur, mais elle a réussi.")
                } catch let error as APIServiceError {
                        if case .responseDecodingFailed(_) = error {
                        } else {
                                
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .responseDecodingFailed attendu. Erreur reçue: \(error)")
                        }
                } catch {
                        // Si l'erreur lancée n'est même pas une APIServiceError, le test échoue.
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
        }
        @Test("Echec dû à une panne réseau :test NetworkFailure")
        func test_getAccountDetails_onNetworkFailure() async throws {
                //ARRANGE
                let simulatedError = URLError(.notConnectedToInternet)
                let failureResult: Result<(Data, URLResponse), Error> = .failure(simulatedError)
                let mockUrlSession = MockURLSession(result: failureResult) //le Mock simule une panne
                let accountService = AccountService(urlSession: mockUrlSession)
                
                //Act & Assert
                let dummyUserSession = UserSession(token: "any-token")
                do {
                        _ = try await accountService.getAccountDetails(identifiant: dummyUserSession)
                        Issue.record("La fonction getAccountDetails() aurait dû lancer une APIServiceError.networkError, mais elle n'a lancé aucune erreur.")
                }
                catch let error as APIServiceError {
                        if case .networkError(_) = error {
                                
                        } else {
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .networkError attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        // Si l'erreur lancée n'est même pas une APIServiceError, le test échoue.
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
                
        }
}///

