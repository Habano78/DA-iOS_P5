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
}
