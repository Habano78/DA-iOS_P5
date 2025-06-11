//
//  TransferServiceTest.swift
//  AuraTests
//
//  Created by Perez William on 09/06/2025.
//

//
import Testing
@testable import Aura
import Foundation

@Suite(.serialized)
struct TransferServiceTests {
        private let transferURL = URL(string: "http://127.0.0.1:8080/account/transfer")!
        
        @Test("sendMoney en cas de succès se termine sans erreur")
        func test_sendMoney_onSuccess_completesWithoutError() async throws {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: transferURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let successResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: successResult)
                let transferService = TransferService(urlSession: mockUrlSession)
                
                // --- ACT & ASSERT ---
                let dataToSend = TransferRequestData(recipient: "contact@aura.app", amount: 50.25)
                let dummyUserSession = UserSession(token: "test_token")
                
                // Si cette ligne lance une erreur, le test échoue. C'est la vérification principale.
                try await transferService.sendMoney(transferData: dataToSend, identifiant: dummyUserSession)
                
                // Vérification que le corps de la requête est correct.
                let capturedRequest = try #require(mockUrlSession.capturedRequest)
                let bodyData = try #require(capturedRequest.httpBody)
                let sentDTO = try JSONDecoder().decode(TransferRequestDTO.self, from: bodyData)
                #expect(sentDTO.recipient == dataToSend.recipient)
                #expect(sentDTO.amount == dataToSend.amount)
        }
        
        @Test("sendMoney en cas de succès se termine sans erreur")
        func test_sendMoney_onInvalidToken_throwsError() async throws {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: transferURL, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let accountService = AccountService(urlSession: mockUrlSession)
                
                // Act & Assert
                do {
                        _ = try await accountService.getAccountDetails(identifiant: UserSession(token: "invalid"))
                        Issue.record("getAccountDetails() aurait dû lancer une erreur.")
                }
                catch let error as APIServiceError {
                        #expect(error == .tokenInvalidOrExpired)
                } catch {
                        Issue.record("Une erreur inattendue a été lancée : \(error)")
                }
        }
}
