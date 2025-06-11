//
//  AuthServiceTests.swift
//  AuraTests
//
//  Created by Perez William on 05/06/2025.
//

import Testing
@testable import Aura
import Foundation

@Suite(.serialized)
struct AuthServiceTests {
        private let authURL = URL(string: "http://127.0.0.1:8080/auth")!
        
        @Test("Login avec succès retourne un UserSession avec le bon token")
        func testLogin_onSuccess_returnsUserSession() async throws {
                // --- ARRANGE ---
                let expectedToken = "token-de-test-succes-456"
                let responseDTO = AuthResponseDTO(token: expectedToken)
                let jsonData = try! JSONEncoder().encode(responseDTO)
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let successResult: Result<(Data, URLResponse), Error> = .success((jsonData, httpResponse))
                
                let mockUrlSession = MockURLSession(result: successResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // --- ACT ---
                let dummyCredentials = AuthRequestDTO(username: "test@aura.app", password: "123")
                let resultingUserSession = try await authService.login(credentials: dummyCredentials)
                
                // --- ASSERT ---
                #expect(resultingUserSession.token == expectedToken)
        }
        
        @Test("Login avec identifiants invalides lance APIServiceError.invalidCredentials")
        func testLogin_onInvalidCredentials_throwsError() async throws {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // --- ACT & ASSERT ---
                let dummyCredentials = AuthRequestDTO(username: "wrongUser", password: "wrongPassword")
                do {
                        _ = try await authService.login(credentials: dummyCredentials)
                        Issue.record("La fonction login() aurait dû lancer une erreur, mais elle a réussi.")
                } catch let error as APIServiceError {
                        #expect(error == .invalidCredentials)
                } catch {
                        Issue.record("Une erreur inattendue a été lancée: \(error)")
                }
        }
}
