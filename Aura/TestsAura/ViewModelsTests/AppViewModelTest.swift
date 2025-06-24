//
//  AppViewModelTest.swift
//  AuraTests
//
//  Created by Perez William on 16/06/2025.
//

import Testing
@testable import Aura
import Foundation

//MARK: Ce (Mock) faux gestionnaire de token nous permettra de simuler la présence ou l'absence d'un token dans le Keychain

private class MockAuthTokenPersistence: AuthTokenPersistenceProtocol {
        
        /// dictionnaire pour simuler le stockage du token.
        private var token: String? = nil
        
        ///Propriété pour forcer le mock à lancer une erreur.
        var shouldThrowError = false
        struct MockPersistenceError: Error, Equatable { let id = UUID() }
        
        ///"Espions" pour vérifier les interactions pendant les tests.
        private(set) var saveTokenCallCount = 0
        private(set) var retrieveTokenCallCount = 0
        private(set) var deleteTokenCallCount = 0
        
        /// Permet de pré-remplir le "faux" Keychain avec un token pour les tests.
        func prefill(token: String?) {
                self.token = token
        }
        
        ///Implémentation des méthodes du protocole
        func saveToken(_ token: String) throws {
                saveTokenCallCount += 1
                if shouldThrowError { struct MockError: Error {}; throw MockError() }
                self.token = token
        }
        
        func retrieveToken() throws -> String? {
                retrieveTokenCallCount += 1
                if shouldThrowError { struct MockError: Error {}; throw MockError() }
                return self.token
        }
        
        func deleteToken() throws {
                deleteTokenCallCount += 1
                if shouldThrowError { struct MockError: Error {}; throw MockError() }
                self.token = nil
        }
}

@Suite(.serialized)
@MainActor
struct AppViewModelTests {
        
        @Test("onLoginSucceed sauvegarde le token et crée les ViewModels de session")
        func testLogin_onManualLoginSuccess_savesTokenAndCreatesViewModels() {
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
        
                mockPersistence.prefill(token: nil)
                
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                let sessionToReturn = UserSession(token: "nouveau-token-manuel")
                
                // ACT (simule l'appel du callback de succès, ce qui déclenche handleLoginSuccess)
                viewModel.authenticationViewModel.onLoginSucceed(sessionToReturn)
                
                // ASSERT
                #expect(mockPersistence.saveTokenCallCount == 1, "saveToken() aurait dû être appelé une fois.")
                /// On vérifie que tous les états de connexion sont corrects
                #expect(viewModel.isLogged == true)
                #expect(viewModel.activeUserSession?.token == sessionToReturn.token)
                #expect(viewModel.stockedAccountDetailViewModel != nil)
                #expect(viewModel.stockedMoneyTransferViewModel != nil)
        }
        
        @Test("init() avec un token existant, connecte l'utilisateur automatiquement")
        func testInit_whenTokenExists_logsInUserAutomatically() async throws {
                // ARRANGE
                let expectedToken = "un-vieux-token-persistant"
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: expectedToken)
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                // ACT
                try await Task.sleep(for: .milliseconds(10))
                
                // ASSERT
                #expect(mockPersistence.retrieveTokenCallCount == 1, "retrieveToken() aurait dû être appelé.")
                #expect(mockPersistence.saveTokenCallCount == 1, "saveToken() aurait dû être appelé par handleLoginSuccess.")
                #expect(viewModel.isLogged == true, "L'utilisateur devrait être connecté.")
                #expect(viewModel.activeUserSession?.token == expectedToken, "Le token de la session est incorrect.")
        }
        
        @Test("init() sans token existant, l'utilisateur reste déconnecté")
        func testInit_whenNoTokenExists_remainsLoggedOut() async throws {
                
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                // ACT
                try await Task.sleep(for: .milliseconds(10))
                
                // ASSERT
                /// Vérifier l'interaction avec la persistance.
                #expect(mockPersistence.retrieveTokenCallCount == 1, "retrieveToken() aurait dû être appelé.")
                #expect(mockPersistence.saveTokenCallCount == 0, "saveToken() ne devrait pas être appelé.")
                #expect(mockPersistence.deleteTokenCallCount == 0, "deleteToken() ne devrait pas être appelé.")
                /// Vérifier que l'état du ViewModel est bien "déconnecté".
                #expect(viewModel.isLogged == false, "L'utilisateur ne devrait pas être connecté.")
                #expect(viewModel.activeUserSession == nil, "Il ne devrait y avoir aucune session active.")
                #expect(viewModel.stockedAccountDetailViewModel == nil, "Aucun ViewModel de détail de compte ne devrait être créé.")
                #expect(viewModel.stockedMoneyTransferViewModel == nil, "Aucun ViewModel de transfert ne devrait être créé.")
        }
        
        @Test("logout() réinitialise tous les états de session et supprime le token")
        func testLogout_resetsSessionStateAndDeleteToken() async {
                
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: "token-qui-sera-supprime")
                
                let viewModel = AppViewModel(
                        authService: MockAuthService(result: .success(UserSession(token: ""))),
                        accountService: MockAccountService(result: .success(.init(totalAmount: 0, transactions: []))),
                        transferService: MockTransferService(result: .success(())),
                        authTokenPersistence: mockPersistence
                )
                
                /// On force manuellement l'état "connecté" pour isoler le test de logout.
                let session = UserSession(token: "token-qui-sera-supprime")
                viewModel.isLogged = true
                viewModel.activeUserSession = session
                viewModel.stockedAccountDetailViewModel = AccountDetailViewModel(accountService: MockAccountService(result: .success(.init(totalAmount: 0, transactions: []))), userSession: session, onSessionExpired: {})
                viewModel.stockedMoneyTransferViewModel = MoneyTransferViewModel(transferService: MockTransferService(result: .success(())), userSession: session)
                
                // ACT
                viewModel.logout()
                
                // ASSERT
                #expect(mockPersistence.deleteTokenCallCount == 1)
                #expect(viewModel.isLogged == false)
                #expect(viewModel.activeUserSession == nil)
                #expect(viewModel.stockedAccountDetailViewModel == nil)
                #expect(viewModel.stockedMoneyTransferViewModel == nil)
        }
        
        @Test("init() en cas d'échec de la récupération du token, l'utilisateur reste déconnecté")
        func testInit_onRetrieveTokenFailure_remainsLoggedOut() async throws {
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.shouldThrowError = true
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                // ACT
                try await Task.sleep(for: .milliseconds(10))
                
                // ASSERT
                #expect(mockPersistence.retrieveTokenCallCount == 1)
                #expect(viewModel.isLogged == false)
                #expect(viewModel.activeUserSession == nil)
        }
        
        @Test("logout() en cas d'échec de la suppression du token, déconnecte quand même l'utilisateur")
        func testLogout_onDeleteTokenFailure_stillLogsOutUser() {
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: "un-token-qui-ne-veut-pas-partir")
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                let session = UserSession(token: "un-token-qui-ne-veut-pas-partir")
                viewModel.isLogged = true
                viewModel.activeUserSession = session
                /// On configure le mock pour qu'il échoue lors de la suppression.
                mockPersistence.shouldThrowError = true
                
                // ACT
                viewModel.logout()
                
                // ASSERT
                #expect(mockPersistence.deleteTokenCallCount == 1)
                #expect(viewModel.isLogged == false, "L'utilisateur devrait être déconnecté même si la suppression du token échoue.")
                #expect(viewModel.activeUserSession == nil, "La session active devrait être nil même si la suppression du token échoue.")
        }
       
        @Test("handleLoginSuccess en cas d'échec de sauvegarde du token, connecte quand même l'utilisateur")
        func testHandleLoginSuccess_onSaveTokenFailure_stillLogsInUser() {
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.shouldThrowError = true
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                let sessionToReturn = UserSession(token: "nouveau-token-qui-va-echouer-a-sauvegarder")
                
                // ACT
                viewModel.authenticationViewModel.onLoginSucceed(sessionToReturn)
                
                // ASSERT
                #expect(mockPersistence.saveTokenCallCount == 1, "saveToken() aurait dû être appelé une fois.")
                #expect(viewModel.isLogged == true, "L'utilisateur devrait être connecté même si la sauvegarde du token a échoué.")
                #expect(viewModel.activeUserSession?.token == sessionToReturn.token, "La session active devrait être définie.")
                #expect(viewModel.stockedAccountDetailViewModel != nil, "Le ViewModel de détail de compte devrait être créé.")
        }
        
        @Test("onSessionExpired callback déclenche bien la déconnexion globale")
        func test_onSessionExpiredCallback_triggersLogout() async throws {
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: "token-valide-au-debut")
                
                let mockAccountService = MockAccountService(result: .failure(APIServiceError.tokenInvalidOrExpired))
                
                let viewModel = AppViewModel(
                        accountService: mockAccountService,
                        authTokenPersistence: mockPersistence
                )
                
                let initialSession = UserSession(token: "token-valide-au-debut")
                viewModel.handleLoginSuccess(for: initialSession) // On utilise la méthode privée pour la préparation
                
                #expect(viewModel.isLogged == true)
                let accountVM = try #require(viewModel.stockedAccountDetailViewModel)
                
                // ACT
                
                await accountVM.getAccountDetails()
                /// BUG! On utilise Task.yield() pour s'assurer que les mises à jour @Published planifiées par logout() ont le temps de s'exécuter.
                await Task.yield()
                
                //  ASSERT
                #expect(viewModel.isLogged == false, "L'utilisateur aurait dû être déconnecté.")
                #expect(viewModel.activeUserSession == nil, "La session active aurait dû être supprimée.")
                #expect(viewModel.stockedAccountDetailViewModel == nil, "Le ViewModel des détails du compte aurait dû être supprimé.")
                #expect(mockPersistence.deleteTokenCallCount == 1, "deleteToken() aurait dû être appelé.")
        }
}
