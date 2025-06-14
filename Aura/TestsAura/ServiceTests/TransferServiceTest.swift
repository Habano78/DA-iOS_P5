//
//  TransferServiceTest.swift
//  AuraTests
//
//  Created by Perez William on 09/06/2025.
//

import Testing
@testable import Aura
import Foundation

@Suite(.serialized)
struct TransferServiceTests {
        private let transferURL = URL(string: "http://127.0.0.1:8080/account/transfer")!
        
        @Test("sendMoney en cas de succès se termine sans erreur et envoie le bon corps")
        func test_sendMoney_onSuccess_completesWithoutError() async throws {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: transferURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let mockSession = MockURLSession(result: .success((Data(), httpResponse)))
                let transferService = TransferService(urlSession: mockSession)
                
                // --- ACT ---
                let dataToSend = TransferRequestData(recipient: "contact@aura.app", amount: 50.25)
                try await transferService.sendMoney(transferData: dataToSend, identifiant: UserSession(token: "test_token"))
                
                // --- ASSERT ---
                let capturedRequest = try #require(mockSession.capturedRequest)
                let bodyData = try #require(capturedRequest.httpBody)
                let sentDTO = try JSONDecoder().decode(TransferRequestDTO.self, from: bodyData)
                #expect(sentDTO.recipient == dataToSend.recipient)
                #expect(sentDTO.amount == dataToSend.amount)
        }
        
        @Test("sendMoney avec un token invalide (401) lance .tokenInvalidOrExpired")
        func test_sendMoney_onInvalidToken_throwsError() async {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: transferURL, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let mockSession = MockURLSession(result: .success((Data(), httpResponse)))
                let transferService = TransferService(urlSession: mockSession)
                
                // --- ACT & ASSERT ---
                do {
                        _ = try await transferService.sendMoney(transferData: .init(recipient: "a", amount: 1), identifiant: .init(token: "invalid"))
                        Issue.record("La fonction sendMoney() aurait dû lancer une erreur.")
                } catch let error as APIServiceError {
                        #expect(error == .tokenInvalidOrExpired)
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
        
        @Test("sendMoney en cas d'erreur serveur (500) lance .unexpectedStatusCode")
        func test_sendMoney_onServerError_throwsUnexpectedStatusCodeError() async {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: transferURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
                let mockSession = MockURLSession(result: .success((Data(), httpResponse)))
                let transferService = TransferService(urlSession: mockSession)
                
                // --- ACT & ASSERT ---
                do {
                        _ = try await transferService.sendMoney(transferData: .init(recipient: "a", amount: 1), identifiant: .init(token: "any"))
                        Issue.record("La fonction sendMoney() aurait dû lancer une erreur.")
                } catch let error as APIServiceError {
                        if case .unexpectedStatusCode(let code) = error {
                                #expect(code == 500)
                        } else {
                                Issue.record("L'erreur attendue était .unexpectedStatusCode(500), mais nous avons reçu \(error)")
                        }
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
        
        @Test("sendMoney en cas de panne réseau lance .networkError")
        func test_sendMoney_onNetworkFailure_throwsNetworkError() async {
                // --- ARRANGE ---
                let simulatedError = URLError(.notConnectedToInternet)
                let mockSession = MockURLSession(result: .failure(simulatedError))
                let transferService = TransferService(urlSession: mockSession)
                
                // --- ACT & ASSERT ---
                do {
                        _ = try await transferService.sendMoney(transferData: .init(recipient: "a", amount: 1), identifiant: .init(token: "any"))
                        Issue.record("La fonction sendMoney() aurait dû lancer une erreur.")
                } catch let error as APIServiceError {
                        if case .networkError = error {
                                // Succès, l'erreur attendue a été attrapée.
                        } else {
                                Issue.record("L'erreur attendue était .networkError, mais nous avons reçu \(error)")
                        }
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
        
        @Test("sendMoney en cas d'échec d'encodage lance .requestEncodingFailed")
        func test_sendMoney_onRequestEncodingFailure_throwsError() async {
                
                // --- ARRANGE ---
                
                // a. On crée notre faux encodeur et on le configure pour qu'il lance une erreur.
                let mockEncoder = MockJSONEncoder()
                mockEncoder.shouldThrowError = true
                
                // b. On crée le service en lui injectant notre faux encodeur.
                //    Le mockUrlSession n'a pas d'importance ici car l'erreur se produira avant l'appel réseau.
                let mockUrlSession = MockURLSession(result: .success((Data(), URLResponse())))
                let transferService = TransferService(urlSession: mockUrlSession, jsonEncoder: mockEncoder)
                
                // --- ACT & ASSERT ---
                
                do {
                        // On appelle la méthode qui devrait échouer lors de l'encodage.
                        _ = try await transferService.sendMoney(transferData: .init(recipient: "a", amount: 1), identifiant: .init(token: "any"))
                        Issue.record("La fonction sendMoney() aurait dû lancer une erreur d'encodage.")
                        
                } catch let error as APIServiceError {
                        // On vérifie que c'est bien le cas d'erreur attendu.
                        if case .requestEncodingFailed = error {
                                // Succès, l'erreur attendue a été attrapée.
                        } else {
                                Issue.record("L'erreur attendue était .requestEncodingFailed, mais nous avons reçu \(error)")
                        }
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
        
        
        // À ajouter dans votre struct TransferServiceTests
        
        @Test("sendMoney avec une réponse non-HTTP lance .networkError")
        func test_sendMoney_onNonHttpResponse_throwsNetworkError() async {
                
                // ARRANGE (Préparation)
                ///On prépare une réponse qui n'est PAS une HTTPURLResponse.
                let nonHttpResponse = URLResponse(
                        url: self.transferURL,
                        mimeType: nil,
                        expectedContentLength: 0,
                        textEncodingName: nil
                )
                
                /// On crée le résultat que le mock doit retourner.
                let nonHttpResult: Result<(Data, URLResponse), Error> = .success((Data(), nonHttpResponse))
                
                ///On crée notre MockURLSession avec ce résultat spécifique.
                let mockUrlSession = MockURLSession(result: nonHttpResult)
                
                ///On crée le service à tester.
                let transferService = TransferService(urlSession: mockUrlSession)
                
                // ACT & Vérifier
                
                let dummyData = TransferRequestData(recipient: "a", amount: 1)
                let dummySession = UserSession(token: "any")
                
                do {
                        _ = try await transferService.sendMoney(transferData: dummyData, identifiant: dummySession)
                        Issue.record("La fonction sendMoney() aurait dû lancer une erreur, mais elle a réussi.")
                        
                } catch let error as APIServiceError {
                        /// On vérifie que c'est bien le cas .networkError.
                        if case .networkError(let underlyingError) = error {
                                // Succès, c'est le bon cas d'erreur.
                                
                                // Vérification avancée : on s'assure que l'erreur sous-jacente
                                // est bien celle que notre service a créée.
                                let urlError = try? #require(underlyingError as? URLError)
                                #expect(urlError?.code == .badServerResponse)
                        } else {
                                Issue.record("L'erreur attendue était .networkError, mais nous avons reçu \(error)")
                        }
                        
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
}
