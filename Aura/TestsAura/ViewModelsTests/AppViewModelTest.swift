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
/// Un "mock" pour la persistance du token. Il simule le comportement du Keychain en utilisant un simple dictionnaire en mémoire.
private class MockAuthTokenPersistence: AuthTokenPersistenceProtocol {
        
        // Un dictionnaire pour simuler le stockage du token.
        private var token: String? = nil
        
        // Propriété pour forcer le mock à lancer une erreur.
        var shouldThrowError = false
        struct MockPersistenceError: Error, Equatable { let id = UUID() } // Une erreur simple pour les tests
        
        // "Espions" pour vérifier les interactions pendant les tests.
        private(set) var saveTokenCallCount = 0
        private(set) var retrieveTokenCallCount = 0
        private(set) var deleteTokenCallCount = 0
        
        /// Permet de pré-remplir le "faux" Keychain avec un token pour les tests.
        func prefill(token: String?) {
                self.token = token
        }
        
        // Implémentation des méthodes du protocole
        
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
        
        //MARK: TEST pour la logique de handleLoginSuccess via le callback
        @Test("onLoginSucceed sauvegarde le token et crée les ViewModels de session")
        func testLogin_onManualLoginSuccess_savesTokenAndCreatesViewModels() {
                // ARRANGE
                let mockPersistence = MockAuthTokenPersistence()
                /// On s'assure que le mock de persistance est vide au début
                mockPersistence.prefill(token: nil)
                
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                let sessionToReturn = UserSession(token: "nouveau-token-manuel")
                
                // ACT
                ///On simule l'appel du callback de succès, ce qui déclenche handleLoginSuccess
                viewModel.authenticationViewModel.onLoginSucceed(sessionToReturn)
                
                //ASSERT
                /// On vérifie que la sauvegarde du token a bien été appelée
                #expect(mockPersistence.saveTokenCallCount == 1, "saveToken() aurait dû être appelé une fois.")
                
                /// On vérifie que tous les états de connexion sont corrects
                #expect(viewModel.isLogged == true)
                #expect(viewModel.activeUserSession?.token == sessionToReturn.token)
                #expect(viewModel.stockedAccountDetailViewModel != nil)
                #expect(viewModel.stockedMoneyTransferViewModel != nil)
        }
        
        // CORRIGÉ : La logique de ce test vérifie maintenant bien l'auto-connexion.
        @Test("init() avec un token existant, connecte l'utilisateur automatiquement")
        func testInit_whenTokenExists_logsInUserAutomatically() async throws {
                // --- ARRANGE ---
                let expectedToken = "un-vieux-token-persistant"
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: expectedToken)
                
                // --- ACT ---
                // On crée le ViewModel. Son 'init' doit déclencher tryAutoLogin.
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                // On attend que la Task asynchrone de l'init ait le temps de s'exécuter.
                try await Task.sleep(for: .milliseconds(10))
                
                // --- ASSERT ---
                #expect(mockPersistence.retrieveTokenCallCount == 1, "retrieveToken() aurait dû être appelé.")
                #expect(mockPersistence.saveTokenCallCount == 1, "saveToken() aurait dû être appelé par handleLoginSuccess.")
                #expect(viewModel.isLogged == true, "L'utilisateur devrait être connecté.")
                #expect(viewModel.activeUserSession?.token == expectedToken, "Le token de la session est incorrect.")
        }
        
        //MARK: Test pour le cas où aucun token n'est trouvé
        @Test("init() sans token existant, l'utilisateur reste déconnecté")
        func testInit_whenNoTokenExists_remainsLoggedOut() async throws {
                
                // ARRANGE
                
                ///On crée un mock de persistance qui est vide par défaut.
                let mockPersistence = MockAuthTokenPersistence()
                
                ///On crée le ViewModel à tester avec ce mock vide.
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                //ACT
                
                // On attend que la tâche asynchrone de l'init ait eu le temps de s'exécuter.
                try await Task.sleep(for: .milliseconds(10))
                
                // ASSERT
                
                // Vérifier l'interaction avec la persistance.
                #expect(mockPersistence.retrieveTokenCallCount == 1, "retrieveToken() aurait dû être appelé.")
                #expect(mockPersistence.saveTokenCallCount == 0, "saveToken() ne devrait pas être appelé.")
                #expect(mockPersistence.deleteTokenCallCount == 0, "deleteToken() ne devrait pas être appelé.")
                
                // Vérifier que l'état du ViewModel est bien "déconnecté".
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
                        // On injecte des mocks vides pour les services non utilisés dans ce test
                        authService: MockAuthService(result: .success(UserSession(token: ""))),
                        accountService: MockAccountService(result: .success(.init(totalAmount: 0, transactions: []))),
                        transferService: MockTransferService(result: .success(())),
                        authTokenPersistence: mockPersistence
                )
                
                // On force manuellement l'état "connecté" pour isoler le test de logout.
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
        
        //MARK: TEST pour l'échec de la récupération du token au démarrage.
        @Test("init() en cas d'échec de la récupération du token, l'utilisateur reste déconnecté")
        func testInit_onRetrieveTokenFailure_remainsLoggedOut() async throws {
                // ARRANGE
                // On configure le mock pour qu'il lance une erreur lors de la récupération.
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.shouldThrowError = true
                
                // ACT
                // On crée le ViewModel. Son init va appeler `tryAutoLogin` qui va échouer.
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                // On attend que la tâche de l'init se termine.
                try await Task.sleep(for: .milliseconds(10))
                
                // ASSERT
                // On vérifie que la récupération a bien été tentée.
                #expect(mockPersistence.retrieveTokenCallCount == 1)
                // On vérifie que l'utilisateur est bien resté dans un état déconnecté.
                #expect(viewModel.isLogged == false)
                #expect(viewModel.activeUserSession == nil)
        }
        
        // MARK: TEST pour l'échec de la suppression du token lors du logout.
        @Test("logout() en cas d'échec de la suppression du token, déconnecte quand même l'utilisateur")
        func testLogout_onDeleteTokenFailure_stillLogsOutUser() {
                // --- ARRANGE ---
                // On prépare le ViewModel dans un état connecté.
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: "un-token-qui-ne-veut-pas-partir")
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                
                let session = UserSession(token: "un-token-qui-ne-veut-pas-partir")
                viewModel.isLogged = true
                viewModel.activeUserSession = session
                
                // On configure le mock pour qu'il échoue lors de la suppression.
                mockPersistence.shouldThrowError = true
                
                // --- ACT ---
                // On appelle la méthode logout.
                viewModel.logout()
                
                // --- ASSERT ---
                // On vérifie que la suppression a bien été tentée.
                #expect(mockPersistence.deleteTokenCallCount == 1)
                // L'ASSERTION LA PLUS IMPORTANTE : même si la suppression du token dans le Keychain a échoué,
                // l'état de l'application en mémoire DOIT être réinitialisé pour la sécurité de l'utilisateur.
                #expect(viewModel.isLogged == false, "L'utilisateur devrait être déconnecté même si la suppression du token échoue.")
                #expect(viewModel.activeUserSession == nil, "La session active devrait être nil même si la suppression du token échoue.")
        }
        
        //MARK: TEST pour l'échec de la sauvegarde du token. Ce test permet de s'assurer que si le Keychain a un problème au moment de sauvegarder le token, l'application ne plante pas et la session de l'utilisateur reste quand même active en mémoire.
        @Test("handleLoginSuccess en cas d'échec de sauvegarde du token, connecte quand même l'utilisateur")
        func testHandleLoginSuccess_onSaveTokenFailure_stillLogsInUser() {
                //ARRANGE
                ///On configure le mock de persistance pour qu'il lance une erreur lors de la sauvegarde.
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.shouldThrowError = true
                ///On crée le ViewModel avec ce mock.
                let viewModel = AppViewModel(authTokenPersistence: mockPersistence)
                ///On prépare la session utilisateur que le callback de login va recevoir.
                let sessionToReturn = UserSession(token: "nouveau-token-qui-va-echouer-a-sauvegarder")
                
                // ACT
                /// On simule manuellement l'appel du callback onLoginSucceed.
                /// Cela déclenche directement la méthode privée handleLoginSuccess que nous voulons tester.
                viewModel.authenticationViewModel.onLoginSucceed(sessionToReturn)
                
                // ASSERT ---
                ///On vérifie que la sauvegarde a bien été tentée.
                #expect(mockPersistence.saveTokenCallCount == 1, "saveToken() aurait dû être appelé une fois.")
                
                ///L'ASSERTION LA PLUS IMPORTANTE : même si la sauvegarde échoue,
                ///l'utilisateur DOIT être connecté pour la session en cours.
                #expect(viewModel.isLogged == true, "L'utilisateur devrait être connecté même si la sauvegarde du token a échoué.")
                #expect(viewModel.activeUserSession?.token == sessionToReturn.token, "La session active devrait être définie.")
                #expect(viewModel.stockedAccountDetailViewModel != nil, "Le ViewModel de détail de compte devrait être créé.")
        }
        
        //MARK: Test pour le callback d'expiration de session. Communication entre Accont et APP
        @Test("onSessionExpired callback déclenche bien la déconnexion globale")
        func test_onSessionExpiredCallback_triggersLogout() async throws {
                // ARRANGE
                ///Configurer le mock de persistance pour qu'il ait un token au début.
                let mockPersistence = MockAuthTokenPersistence()
                mockPersistence.prefill(token: "token-valide-au-debut")
                
                ///Configurer le mock de AccountService pour qu'il lance une erreur de token expiré.
                let mockAccountService = MockAccountService(result: .failure(APIServiceError.tokenInvalidOrExpired))
                
                ///Créer AppViewModel avec ses mocks.
                let viewModel = AppViewModel(
                        accountService: mockAccountService,
                        authTokenPersistence: mockPersistence
                )
                
                ///Forcer manuellement l'état "connecté" pour isoler le test.
                let initialSession = UserSession(token: "token-valide-au-debut")
                viewModel.handleLoginSuccess(for: initialSession) // On utilise la méthode privée pour la préparation
                
                ///Pré-vérification : s'assurer que l'état initial est bien "connecté".
                #expect(viewModel.isLogged == true)
                let accountVM = try #require(viewModel.stockedAccountDetailViewModel)
                
                // ACT
                ///On appelle la méthode qui va déclencher l'erreur dans le service,
                ///ce qui doit appeler le callback et déclencher logout() dans AppViewModel.
                await accountVM.getAccountDetails()
                /// BUG! On utilise Task.yield() pour s'assurer que les mises à jour @Published planifiées par logout() ont le temps de s'exécuter.
                await Task.yield()
                
                // ASSERT
                ///On vérifie que la méthode de déconnexion a bien fait son travail.
                #expect(viewModel.isLogged == false, "L'utilisateur aurait dû être déconnecté.")
                #expect(viewModel.activeUserSession == nil, "La session active aurait dû être supprimée.")
                #expect(viewModel.stockedAccountDetailViewModel == nil, "Le ViewModel des détails du compte aurait dû être supprimé.")
                
                // On vérifie que la suppression du token a bien été tentée.
                #expect(mockPersistence.deleteTokenCallCount == 1, "deleteToken() aurait dû être appelé.")
        }
}
