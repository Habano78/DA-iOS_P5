//
//  AuthenticationViewModelTests.swift
//  AuraTests
//
//  Created by Perez William on 12/06/2025.
//
import Testing
@testable import Aura
import Foundation



//MARK: TESTs
@Suite(.serialized)
@MainActor
struct AuthenticationViewModelTests {
        
        @Test("login() en cas de succès, met à jour les états et appelle le callback")
        func testLogin_onSuccess_updatesStateAndCallsCallback() async {
                
                //ARRANGE
                /// Préparer le résultat de succès que notre mock service retournera.
                let expectedUserSession = UserSession(token: "token-de-test-pour-vm")
                let mockService = MockAuthService(result: .success(expectedUserSession))
                
                ///On vérifie ici que le callback est bien appelé.
                ///Ce sont de simples variables locales que la closure du callback va modifier.
                var wasCallbackCalled = false
                var receivedSession: UserSession?
                
                /// On définit la closure du callback.
                let successCallback: (UserSession) -> Void = { session in
                        // Quand ce callback sera appelé par le ViewModel, il mettra à jour nos espions.
                        wasCallbackCalled = true
                        receivedSession = session
                }
                
                // d. Créer l'instance du ViewModel à tester (le "System Under Test" ou SUT).
                //    On lui injecte notre service mocké et notre callback espion.
                let viewModel = AuthenticationViewModel(
                        authService: mockService,
                        onLoginSucceed: successCallback
                )
                
                //Simuler la saisie de l'utilisateur dans les champs de la vue.
                viewModel.username = "test@user.com"
                viewModel.password = "password123"
                
                //ACT (Agir) ---
                
                // On appelle la seule méthode que l'on veut tester.
                await viewModel.login()
                
                // ASSERT (Vérifier) ---
                // On vérifie que tout s'est passé comme prévu après l'action.
                
                // a. Vérifier les états finaux du ViewModel.
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                #expect(viewModel.errorMessage == nil, "errorMessage devrait être nil en cas de succès.")
                
                // Vérifier que le ViewModel a bien interagi avec le service.
                #expect(mockService.loginCallCount == 1, "La méthode login du service aurait dû être appelée une seule fois.")
                #expect(mockService.receivedCredentials?.username == "test@user.com", "Le username envoyé au service est incorrect.")
                #expect(mockService.receivedCredentials?.password == "password123", "Le mot de passe envoyé au service est incorrect.")
                
                // Vérifier que le callback de succès a été appelé avec les bonnes données.
                #expect(wasCallbackCalled == true, "Le callback onLoginSucceed aurait dû être appelé.")
                #expect(receivedSession?.token == expectedUserSession.token, "Le UserSession reçu par le callback est incorrect.")
        }
        //MARK: on verifie ici que si le service lance une erreur, le ViewModel met bien à jour errorMessage et isLoading, et n'appelle pas le callback de succès.
        @Test("login() en cas d'échec, met à jour le message d'erreur")
        func testLogin_onFailure_updatesErrorMessage() async {
                
                // ARRANGE
                ///Préparer le résultat d'échec que le mock retournera.
                let expectedError = APIServiceError.invalidCredentials
                let mockService = MockAuthService(result: .failure(expectedError))
                /// Préparer un "espion" pour vérifier que le callback de succès n'est PAS appelé.
                var wasSuccessCallbackCalled = false
                let successCallback: (UserSession) -> Void = { _ in
                        /// Si ce code est exécuté, c'est un échec pour le test.
                        wasSuccessCallbackCalled = true
                        Issue.record("Le callback de succès ne devrait pas être appelé en cas d'échec.")
                }
                
                ///Créer l'instance du ViewModel à tester.
                let viewModel = AuthenticationViewModel(
                        authService: mockService,
                        onLoginSucceed: successCallback
                )
                ///Simuler la saisie de l'utilisateur.
                viewModel.username = "wrong@user.com"
                viewModel.password = "wrongPassword"
                
                //ACT
                ///On appelle la méthode que l'on veut tester.
                await viewModel.login()
                
                // ASSERT
                ///Vérifier les états finaux du ViewModel.
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                #expect(wasSuccessCallbackCalled == false, "Le callback de succès a été appelé par erreur.")
                #expect(viewModel.errorMessage == expectedError.errorDescription, "Le message d'erreur ne correspond pas à l'erreur attendue.")
                
                // b. Vérifier que le message d'erreur a été correctement défini.
                #expect(viewModel.errorMessage == expectedError.errorDescription, "Le message d'erreur ne correspond pas à l'erreur attendue.")
                
                // c. Vérifier que le callback de succès n'a PAS été appelé.
                #expect(wasSuccessCallbackCalled == false, "Le callback de succès a été appelé par erreur.")
                
                // d. Vérifier que le service a quand même été appelé.
                #expect(mockService.loginCallCount == 1, "La méthode login du service aurait dû être appelée une fois.")
        }
        
        //MARK: Test pour une erreur inattendue
        @Test("login() en cas d'erreur inattendue, affiche un message générique")
        func testLogin_onUnexpectedError_setsGenericErrorMessage() async {
                // --- ARRANGE ---
                ///On définit une erreur personnalisée qui n'est PAS une APIServiceError
                struct CustomError: Error {}
                let unexpectedError = CustomError()
                let mockService = MockAuthService(result: .failure(unexpectedError))
                
                ///Créer l'instance du ViewModel à tester.
                let viewModel = AuthenticationViewModel(
                        authService: mockService,
                        onLoginSucceed: {_ in Issue.record("Le callback de succès ne devrait pas être appelé.") }
                )
                viewModel.username = "user"
                viewModel.password = "Password"
                
                //ACT
                await viewModel.login()
                
                //ASSERT
                #expect(viewModel.errorMessage == "Erreur inattendue.Veuillez réessayer.")
                #expect(mockService.loginCallCount == 1)
        }
}
