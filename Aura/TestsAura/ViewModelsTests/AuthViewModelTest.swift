//
//  AuthenticationViewModelTests.swift
//  AuraTests
//
//  Created by Perez William on 12/06/2025.
//
import Testing
@testable import Aura
import Foundation


@Suite(.serialized)
@MainActor
struct AuthenticationViewModelTests {
        
        @Test("login() en cas de succès, met à jour les états et appelle le callback")
        func testLogin_onSuccess_updatesStateAndCallsCallback() async {
                
                // ARRANGE : préparer le résultat de succès que notre mock service retournera.
                let expectedUserSession = UserSession(token: "token-de-test-pour-vm")
                let mockService = MockAuthService(result: .success(expectedUserSession))
               
                var wasCallbackCalled = false
                var receivedSession: UserSession?
                
                let successCallback: (UserSession) -> Void = { session in
                        wasCallbackCalled = true
                        receivedSession = session
                }
                
                let viewModel = AuthenticationViewModel(
                        authService: mockService,
                        onLoginSucceed: successCallback
                )
                
                viewModel.username = "test@user.com"
                viewModel.password = "password123"
                
                // ACT
                await viewModel.login()
                
                // ASSERT
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                #expect(viewModel.errorMessage == nil, "errorMessage devrait être nil en cas de succès.")
               
                #expect(mockService.loginCallCount == 1, "La méthode login du service aurait dû être appelée une seule fois.")
                #expect(mockService.receivedCredentials?.username == "test@user.com", "Le username envoyé au service est incorrect.")
                #expect(mockService.receivedCredentials?.password == "password123", "Le mot de passe envoyé au service est incorrect.")
                
                #expect(wasCallbackCalled == true, "Le callback onLoginSucceed aurait dû être appelé.")
                #expect(receivedSession?.token == expectedUserSession.token, "Le UserSession reçu par le callback est incorrect.")
        }
        
        @Test("login() en cas d'échec, met à jour le message d'erreur")
        func testLogin_onFailure_updatesErrorMessage() async {
                
                // ARRANGE
                let expectedError = APIServiceError.invalidCredentials
                let mockService = MockAuthService(result: .failure(expectedError))
                var wasSuccessCallbackCalled = false
                let successCallback: (UserSession) -> Void = { _ in
                        wasSuccessCallbackCalled = true
                        Issue.record("Le callback de succès ne devrait pas être appelé en cas d'échec.")
                }
                
                let viewModel = AuthenticationViewModel(
                        authService: mockService,
                        onLoginSucceed: successCallback
                )
             
                viewModel.username = "wrong@user.com"
                viewModel.password = "wrongPassword"
                
                // ACT
                await viewModel.login()
                
                // ASSERT
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                #expect(wasSuccessCallbackCalled == false, "Le callback de succès a été appelé par erreur.")
                #expect(viewModel.errorMessage == expectedError.errorDescription, "Le message d'erreur ne correspond pas à l'erreur attendue.")
                #expect(viewModel.errorMessage == expectedError.errorDescription, "Le message d'erreur ne correspond pas à l'erreur attendue.")
                #expect(wasSuccessCallbackCalled == false, "Le callback de succès a été appelé par erreur.")
                #expect(mockService.loginCallCount == 1, "La méthode login du service aurait dû être appelée une fois.")
        }
        
        @Test("login() en cas d'erreur inattendue, affiche un message générique")
        func testLogin_onUnexpectedError_setsGenericErrorMessage() async {
                // ARRANGE
                struct CustomError: Error {}
                let unexpectedError = CustomError()
                let mockService = MockAuthService(result: .failure(unexpectedError))
                
                let viewModel = AuthenticationViewModel(
                        authService: mockService,
                        onLoginSucceed: {_ in Issue.record("Le callback de succès ne devrait pas être appelé.") }
                )
                viewModel.username = "user"
                viewModel.password = "Password"
                
                // ACT
                await viewModel.login()
                
                // ASSERT
                #expect(viewModel.errorMessage == "Erreur inattendue.Veuillez réessayer.")
                #expect(mockService.loginCallCount == 1)
        }
}
