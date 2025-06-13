//
//  AppViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

// AppViewModel.swift
import Foundation
@MainActor /// pour garabtir que toutes les propriétés sont modofiées sur le fil principal
class AppViewModel: ObservableObject {
        @Published var isLogged: Bool
        @Published var activeUserSession: UserSession? /// Propriété ajoutée  pour stocker le UserSession. Optionnel, car nil si non connecté
        //MARK: Changements importants : Contrairement à authentificationViewModel, AccountDetail et MoneyTransfer ViewModels deviennet de propriètés stockées et optionnelles. Le but de les déclarer ici est de les avoir 
        @Published private(set) var stockedAccountDetailViewModel: AccountDetailViewModel?
        @Published private(set) var stockedMoneyTransferViewModel: MoneyTransferViewModel?
        
        //MARK: nouvelles propriétés d'instance qu'AppViewModel doit transmettre au viewmodels respectifs
        private let authService: AuthenticationServiceProtocol
        private let accountService: AccountServiceProtocol
        private let transferService: TransferServiceProtocol
        private let authTokenPersistence: AuthTokenPersistence ///pour la sauvegarde, la récupération et la suppression du token,
        
        //MARK: init
        init() {
                // Initialisation des services et la persistance
                self.authService = AuthService()
                self.accountService = AccountService()
                self.transferService = TransferService()
                self.authTokenPersistence = AuthTokenPersistence()
                // Initialiser les états
                self.isLogged = false
                self.activeUserSession = nil
                self.stockedAccountDetailViewModel = nil
                self.stockedMoneyTransferViewModel = nil
                
                Task { // Lancement d'une tâche asynchrone pour tenter de récupérer le token
                        // Ce code à l'intérieur de Task { @MainActor in ... } s'exécute sur le thread principal
                        do {
                                /// On appelle retrieveToken() dans AuthTokenPersistence et on verifie si il le token est retourné et s'il n'est pas vide
                                if let retrievedToken = try self.authTokenPersistence.retrieveToken(), !retrievedToken.isEmpty {
                                        
                                        /// si token trouvé et pas vide on crée UserSession et on met à jour les propriétés pour refléter l'état connecté
                                        print("AppViewModel: Token valide récupéré du Keychain : \(retrievedToken.prefix(8))...")
                                        let session = UserSession(token: retrievedToken)
                                        self.activeUserSession = session
                                        self.isLogged = true
                                        
                                        //Puisque nous avons une session, on peut alors créer les ViewModels qui en dépendent
                                        self.stockedAccountDetailViewModel = AccountDetailViewModel(
                                                accountService: self.accountService,
                                                userSession: session
                                        )
                                        self.stockedMoneyTransferViewModel = MoneyTransferViewModel(
                                                transferService: self.transferService,
                                                userSession: session
                                        )
                                        print("AppViewModel: Utilisateur auto-connecté avec le token du Keychain.")
                                } else {
                                        ///Si Aucun token trouvé dans le Keychain, ou token vide.L'utilisateur reste déconnecté (isLogged reste false, activeUserSession reste nil).
                                        print("AppViewModel: Aucun token valide trouvé dans le Keychain pour l'auto-connexion.")
                                }
                        } catch KeychainService.KeychainError.itemNotFound {
                                print("AppViewModel: Aucun token dans le Keychain (itemNotFound).")
                        } catch {
                                // Toute autre erreur potentielle du Keychain (ex: problème d'accès, données corrompues).
                                print("AppViewModel: ERREUR lors de la récupération du token depuis le Keychain: \(error.localizedDescription)")
                                // On ne met pas à jour errorMessage ici car c'est l'init, pas une action utilisateur directe.
                        }
                }
        }
        
        // ViewModel d'authentification
        var authenticationViewModel: AuthenticationViewModel {
                return AuthenticationViewModel (
                        authService: self.authService,
                        onLoginSucceed: { [weak self] receivedUserSession in // Le callback reçoit UserSession
                                guard let self = self else { return }
                                
                                // Sauvegarder le token dans le Keychain
                                do {
                                        try self.authTokenPersistence.saveToken(receivedUserSession.token)
                                        print("AppViewModel: Token sauvegardé dans le Keychain.")
                                } catch {
                                }
                                
                                //MARK: Mise à jour de l'état de l'application
                                self.activeUserSession = receivedUserSession
                                self.isLogged = true
                                
                                self.stockedAccountDetailViewModel = AccountDetailViewModel(
                                        accountService: self.accountService,
                                        userSession: receivedUserSession
                                )
                                self.stockedMoneyTransferViewModel = MoneyTransferViewModel(
                                        transferService: self.transferService,
                                        userSession: receivedUserSession
                                )
                        }
                )
        }
        
        //MARK: Déconnexion
        func logout() {
                print("AppViewModel: Déconnexion demandée.")
                // ici on supprime le tokendu Keychain
                do {
                        try self.authTokenPersistence.deleteToken()
                        print("AppViewModel: Token supprimé du Keychain.")
                } catch {
                        print("AppViewModel: ERREUR lors de la suppression du token du Keychain: \(error.localizedDescription)")
                        // Continuer la déconnexion de l'état en mémoire de toute façon.
                }
                
                //MARK: Réinitialisation de l'état de l'application
                self.isLogged = false
                self.activeUserSession = nil
                self.stockedAccountDetailViewModel = nil
                self.stockedMoneyTransferViewModel = nil
                print("AppViewModel: État de déconnexion appliqué.")
        }
}
//MARK: // L'ancienne propriété calculée 'accountDetailViewModel' qui retournait AccountDetailViewModel()
// est implicitement remplacée par l'utilisation de 'stockedAccountDetailViewModel'.
// Les vues qui ont besoin de AccountDetailViewModel utiliseront maintenant
// appViewModel.stockedAccountDetailViewModel (et géreront son optionalité).
