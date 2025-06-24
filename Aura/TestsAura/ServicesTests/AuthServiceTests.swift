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
                // ARRANGE
                let expectedToken = "token-de-test-succes-456"
                let responseDTO = AuthResponseDTO(token: expectedToken)
                let jsonData = try! JSONEncoder().encode(responseDTO)
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let successResult: Result<(Data, URLResponse), Error> = .success((jsonData, httpResponse))
                
                let mockUrlSession = MockURLSession(result: successResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // ACT
                let dummyCredentials = AuthRequestDTO(username: "test@aura.app", password: "123")
                let resultingUserSession = try await authService.login(credentials: dummyCredentials)
                
                // ASSERT
                #expect(resultingUserSession.token == expectedToken)
        }
        
        @Test("Login avec identifiants invalides lance APIServiceError.invalidCredentials")
        func testLogin_onInvalidCredentials_throwsError() async throws {
                // --- ARRANGE ---
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // ACT & ASSERT
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
        
        @Test("Login en cas d'erreur serveur (500) lance l'erreur .unexpectedStatusCode")
        func testLogin_onServerError_throwsUnexpectedStatusCodeError() async throws {
                // ARRANGE: configuration du Mock pour retourner statu 500 ---
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // ACT & ASSERT
                let dummyCredentials = AuthRequestDTO(username: "wrongUser", password: "wrongPassword")
                do {
                        _ = try await authService.login(credentials: dummyCredentials)
                        Issue.record("La fonction login() aurait dû lancer une erreur, mais elle a réussi.")
                        
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
        
        @Test("Login avec un JSON de réponse invalide lance l'erreur .responseDecodingFailed")
        func testLogin_onBadJSONResponse_throwsDecodingFailedError1() async throws {
                
                // ARRANGE: configuration du Mock pour retourner statu 200 ---
                let invalidJsonString = """
                    {
                        "tokken": "ce-token-ne-sera-jamais-lu"
                    }
                    """
                let invalidJsonData = invalidJsonString.data(using: .utf8)!
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let badDataSuccessResult: Result<(Data, URLResponse), Error> = .success((invalidJsonData, httpResponse))
                let mockUrlSession = MockURLSession(result: badDataSuccessResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // ACT & ASSERT
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                
                /// On utilise un bloc do-catch pour vérifier que l'erreur de décodage attendue est bien lancée.
                do {
                        _ = try await authService.login(credentials: dummyCredentials)
                        
                        Issue.record("La fonction login() aurait dû lancer une APIServiceError.responseDecodingFailed, mais elle n'a lancé aucune erreur.")
                        
                } catch let error as APIServiceError {
                        
                        if case .responseDecodingFailed(_) = error {
                                
                        } else {
                                
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .responseDecodingFailed attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
        }
        
        @Test("Login avec un JSON de réponse invalide (not STRING)).responseDecodingFailed")
        func testLogin_onBadJSONResponse_throwsDecodingFailedError2() async throws {
                // ARRANGE: configuration du Mock pour retourner statu 200 ---
                let invalidJsonString = """
                    {
                        "token": 1235
                    }
                    """
                let invalidJsonData = invalidJsonString.data(using: .utf8)!
                
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                
                let badDataSuccessResult: Result<(Data, URLResponse), Error> = .success((invalidJsonData, httpResponse))
                let mockUrlSession = MockURLSession(result: badDataSuccessResult)
                
                let authService = AuthService(urlSession: mockUrlSession)
                
                // ACT & ASSERT
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                
                do {
                        
                        _ = try await authService.login(credentials: dummyCredentials)
                        
                        Issue.record("La fonction login() aurait dû lancer une APIServiceError.responseDecodingFailed, mais elle n'a lancé aucune erreur.")
                        
                } catch let error as APIServiceError {
                        
                        if case .responseDecodingFailed(_) = error {
                                
                        } else {
                                
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .responseDecodingFailed attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
        }
        
        @Test("Echec dû à une panne réseau")
        func testLogin_onNetworkFailure_throwsNetworkError() async throws {
                // ARRANGE
                let simulatedError = URLError(.notConnectedToInternet)
                let failureResult: Result<(Data, URLResponse), Error> = .failure(simulatedError)
                let mockUrlSession = MockURLSession(result: failureResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // Act & Assert
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                do {
                        _ = try await authService.login (credentials: dummyCredentials)
                        Issue.record("La fonction login() aurait dû lancer une APIServiceError.networkError, mais elle n'a lancé aucune erreur.")
                }
                catch let error as APIServiceError {
                        
                        if case .networkError(_) = error {
                                
                        } else {
                                
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .networkError attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
                
        }
        @Test("Login avec une réponse non-HTTP lance .networkError")
        func testLogin_onNonHttpResponse_throwsNetworkError() async {
                
                // ARRANGE : réponse qui n'est PAS une HTTPURLResponse.
                let nonHttpResponse = URLResponse(
                        url: authURL,
                        mimeType: nil,
                        expectedContentLength: 0,
                        textEncodingName: nil
                )
                
                let nonHttpResult: Result<(Data, URLResponse), Error> = .success((Data(), nonHttpResponse))
                
                let mockUrlSession = MockURLSession(result: nonHttpResult)
                
                let authService = AuthService(urlSession: mockUrlSession)
                
                // ACT & ASSERT
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                
                do {
                        _ = try await authService.login(credentials: dummyCredentials)
                        Issue.record("La fonction login() aurait dû lancer une erreur, mais elle a réussi.")
                        
                } catch let error as APIServiceError {
                        
                        if case .networkError(let underlyingError) = error {
                                
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
