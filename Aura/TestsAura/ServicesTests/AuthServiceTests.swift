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
        
        @Test("Login en cas d'erreur serveur (500) lance l'erreur .unexpectedStatusCode")
        func testLogin_onServerError_throwsUnexpectedStatusCodeError() async throws {
                // --- ARRANGE: configuration du Mock pour retourner statu 500 ---
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
                let failureResult: Result<(Data, URLResponse), Error> = .success((Data(), httpResponse))
                let mockUrlSession = MockURLSession(result: failureResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                // --- ACT & ASSERT ---
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
                // --- ARRANGE: configuration du Mock pour retourner statu 200 ---
                // a. On prépare le JSON invalide. Ici, la clé "token" est mal orthographiée "tokken".
                let invalidJsonString = """
                    {
                        "tokken": "ce-token-ne-sera-jamais-lu"
                    }
                    """
                let invalidJsonData = invalidJsonString.data(using: .utf8)!
                
                ///Le serveur nous dit que tout va bien, or ses données sont corrompues.
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                /// DONNÉES INVALIDES pour le MOCK
                let badDataSuccessResult: Result<(Data, URLResponse), Error> = .success((invalidJsonData, httpResponse))
                let mockUrlSession = MockURLSession(result: badDataSuccessResult)
                /// On crée le service à tester en lui injectant notre mock.
                let authService = AuthService(urlSession: mockUrlSession)
                
                // --- ACT & ASSERT ---
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                
                // On utilise un bloc do-catch pour vérifier que l'erreur de décodage attendue est bien lancée.
                do {
                        // On essaie d'appeler la méthode login. On s'attend à ce que cette ligne lance une erreur
                        // lorsque le service tentera de décoder le JSON invalide.
                        _ = try await authService.login(credentials: dummyCredentials)
                        
                        // Si le code arrive jusqu'ici, cela signifie qu'aucune erreur n'a été lancée.
                        // C'est un échec pour ce test, donc on le signale explicitement.
                        Issue.record("La fonction login() aurait dû lancer une APIServiceError.responseDecodingFailed, mais elle n'a lancé aucune erreur.")
                        
                } catch let error as APIServiceError {
                        // CORRECTION : On utilise un 'switch' pour vérifier le cas de l'erreur.
                        if case .responseDecodingFailed(_) = error {
                                // C'est le chemin de succès du test. L'erreur attendue a été attrapée.
                                // Il n'y a pas besoin de #expect ici, car le simple fait d'entrer dans ce bloc
                                // constitue la réussite de la vérification.
                        } else {
                                // Si une APIServiceError a été attrapée, mais que ce n'était pas
                                // le cas .responseDecodingFailed que nous attendions, le test échoue.
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .responseDecodingFailed attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        // Si l'erreur lancée n'est même pas une APIServiceError, le test échoue.
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
        }
        
        @Test("Login avec un JSON de réponse invalide (not STRING)).responseDecodingFailed")
        func testLogin_onBadJSONResponse_throwsDecodingFailedError2() async throws {
                // --- ARRANGE: configuration du Mock pour retourner statu 200 ---
                // a. On prépare le JSON invalide. Ici, la clé "token" est mal orthographiée "tokken".
                let invalidJsonString = """
                    {
                        "token": 1235
                    }
                    """
                let invalidJsonData = invalidJsonString.data(using: .utf8)!
                
                ///Le serveur nous dit que tout va bien, or ses données sont corrompues.
                let httpResponse = HTTPURLResponse(url: authURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                /// DONNÉES INVALIDES pour le MOCK
                let badDataSuccessResult: Result<(Data, URLResponse), Error> = .success((invalidJsonData, httpResponse))
                let mockUrlSession = MockURLSession(result: badDataSuccessResult)
                /// On crée le service à tester en lui injectant notre mock.
                let authService = AuthService(urlSession: mockUrlSession)
                
                // --- ACT & ASSERT ---
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                
                // On utilise un bloc do-catch pour vérifier que l'erreur de décodage attendue est bien lancée.
                do {
                        // On essaie d'appeler la méthode login. On s'attend à ce que cette ligne lance une erreur
                        // lorsque le service tentera de décoder le JSON invalide.
                        _ = try await authService.login(credentials: dummyCredentials)
                        
                        Issue.record("La fonction login() aurait dû lancer une APIServiceError.responseDecodingFailed, mais elle n'a lancé aucune erreur.")
                        
                } catch let error as APIServiceError {
                        // CORRECTION : On utilise un 'switch' pour vérifier le cas de l'erreur.
                        if case .responseDecodingFailed(_) = error {
                                // C'est le chemin de succès du test. L'erreur attendue a été attrapée.
                                // Il n'y a pas besoin de #expect ici, car le simple fait d'entrer dans ce bloc
                                // constitue la réussite de la vérification.
                        } else {
                                // Si une APIServiceError a été attrapée, mais que ce n'était pas
                                // le cas .responseDecodingFailed que nous attendions, le test échoue.
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .responseDecodingFailed attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        // Si l'erreur lancée n'est même pas une APIServiceError, le test échoue.
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
        }
        
        @Test("Echec dû à une panne réseau")
        func testLogin_onNetworkFailure_throwsNetworkError() async throws {
                //ARRANGE
                let simulatedError = URLError(.notConnectedToInternet)
                let failureResult: Result<(Data, URLResponse), Error> = .failure(simulatedError)
                let mockUrlSession = MockURLSession(result: failureResult)
                let authService = AuthService(urlSession: mockUrlSession)
                
                //Act & Assert
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                do {
                        _ = try await authService.login (credentials: dummyCredentials)
                        Issue.record("La fonction login() aurait dû lancer une APIServiceError.networkError, mais elle n'a lancé aucune erreur.")
                }
                catch let error as APIServiceError {
                        // CORRECTION : On utilise un 'switch' pour vérifier le cas de l'erreur.
                        if case .networkError(_) = error {
                                // L'erreur attendue a été attrapée.
                                // Pas besoin de #expect ici : le simple fait d'entrer dans ce bloc
                                // constitue la réussite de la vérification.
                        } else {
                                // Si une APIServiceError a été attrapée, mais que ce n'était pas
                                // le cas .responseDecodingFailed que nous attendions, le test échoue.
                                Issue.record("Une APIServiceError a été lancée, mais ce n'était pas le cas .networkError attendu. Erreur reçue: \(error)")
                        }
                        
                } catch {
                        // Si l'erreur lancée n'est même pas une APIServiceError, le test échoue.
                        Issue.record("Une erreur inattendue et d'un type non-APIServiceError a été lancée: \(error)")
                }
                
        }
        @Test("Login avec une réponse non-HTTP lance .networkError")
        func testLogin_onNonHttpResponse_throwsNetworkError() async {
                
                //  Préparation
                
                //Ici On prépare une réponse qui n'est PAS une HTTPURLResponse.
                let nonHttpResponse = URLResponse(
                        url: authURL,
                        mimeType: nil,
                        expectedContentLength: 0,
                        textEncodingName: nil
                )
                
                // b. On crée le résultat que le mock doit retourner.
                let nonHttpResult: Result<(Data, URLResponse), Error> = .success((Data(), nonHttpResponse))
                
                // c. On crée notre MockURLSession avec ce résultat spécifique.
                let mockUrlSession = MockURLSession(result: nonHttpResult)
                
                // d. On crée le service à tester.
                let authService = AuthService(urlSession: mockUrlSession)
                
                // --- 2. ACT (Agir) & 3. ASSERT (Vérifier) ---
                let dummyCredentials = AuthRequestDTO(username: "user", password: "pass")
                
                do {
                        _ = try await authService.login(credentials: dummyCredentials)
                        Issue.record("La fonction login() aurait dû lancer une erreur, mais elle a réussi.")
                        
                } catch let error as APIServiceError {
                        // On vérifie que c'est bien le cas .networkError.
                        if case .networkError(let underlyingError) = error {
                                // On s'attend à ce que l'erreur sous-jacente soit celle que nous avons lancée.
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
