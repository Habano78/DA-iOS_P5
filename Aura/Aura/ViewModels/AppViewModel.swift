//
//  AppViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

// AppViewModel.swift
import Foundation

@MainActor
class AppViewModel: ObservableObject {
        
        @Published var isLogged: Bool
        @Published var activeUserSession: UserSession?
        
        @Published private(set) var stockedAccountDetailViewModel: AccountDetailViewModel?
        @Published private(set) var stockedMoneyTransferViewModel: MoneyTransferViewModel?
        
        // Services et persistance
        private let authService: AuthenticationServiceProtocol
        private let accountService: AccountServiceProtocol
        private let transferService: TransferServiceProtocol
        private let authTokenPersistence: AuthTokenPersistence
        
        init() {
                // Initialisation des services et de la persistance
                self.authService = AuthService()
                self.accountService = AccountService()
                self.transferService = TransferService()
                self.authTokenPersistence = AuthTokenPersistence()
                
                // Initialisation des états
                self.isLogged = false
                
                // Tâche asynchrone pour tenter de récupérer un token existant
                Task {
                        await self.tryAutoLogin()
                }
        }
        
        // ViewModel d'authentification
        var authenticationViewModel: AuthenticationViewModel {
                return AuthenticationViewModel (
                        authService: self.authService,
                        onLoginSucceed: { [weak self] receivedUserSession in
                                self?.handleLoginSuccess(for: receivedUserSession)
                        }
                )
        }
        
        // Fonction pour gérer la logique après un succès de connexion
        private func handleLoginSuccess(for session: UserSession) {
                print("AppViewModel: onLoginSucceed - Connexion réussie.")
                // Sauvegarder le token dans le Keychain
                do {
                        try self.authTokenPersistence.saveToken(session.token)
                        print("AppViewModel: Token sauvegardé dans le Keychain.")
                } catch {
                        print("AppViewModel: ERREUR lors de la sauvegarde du token: \(error.localizedDescription)")
                }
                
                // Mettre à jour l'état de l'application
                self.activeUserSession = session
                self.isLogged = true
                
                // NOUVEAU : On définit le callback de déconnexion
                let sessionExpiredCallback = { [weak self] in
                        print("AppViewModel: Callback onSessionExpired reçu, déconnexion en cours...")
                        self?.logout()
                }
                
                // Créer les ViewModels dépendants avec leurs dépendances et le callback
                self.stockedAccountDetailViewModel = AccountDetailViewModel(
                        accountService: self.accountService,
                        userSession: session,
                        onSessionExpired: sessionExpiredCallback // On passe le callback ici
                )
                self.stockedMoneyTransferViewModel = MoneyTransferViewModel(
                        transferService: self.transferService,
                        userSession: session
                        // Si MoneyTransferViewModel a aussi besoin de déconnecter, on lui passerait aussi le callback
                )
        }
        
        // Fonction de déconnexion
        func logout() {
                print("AppViewModel: Déconnexion demandée.")
                // Supprimer le token du Keychain
                do {
                        try self.authTokenPersistence.deleteToken()
                        print("AppViewModel: Token supprimé du Keychain.")
                } catch {
                        print("AppViewModel: ERREUR lors de la suppression du token: \(error.localizedDescription)")
                }
                
                // Réinitialisation de l'état de l'application
                self.isLogged = false
                self.activeUserSession = nil
                self.stockedAccountDetailViewModel = nil
                self.stockedMoneyTransferViewModel = nil
                print("AppViewModel: État de déconnexion appliqué.")
        }
        
        // Fonction pour la tentative de connexion automatique au démarrage
        private func tryAutoLogin() async {
                print("AppViewModel: Tentative de récupération du token existant...")
                do {
                        if let retrievedToken = try self.authTokenPersistence.retrieveToken(), !retrievedToken.isEmpty {
                                print("AppViewModel: Token valide récupéré du Keychain.")
                                let session = UserSession(token: retrievedToken)
                                // On utilise la même logique que pour un login normal
                                self.handleLoginSuccess(for: session)
                                print("AppViewModel: Utilisateur auto-connecté avec le token du Keychain.")
                        } else {
                                print("AppViewModel: Aucun token valide trouvé pour l'auto-connexion.")
                        }
                } catch {
                        print("AppViewModel: ERREUR lors de la récupération du token depuis le Keychain: \(error.localizedDescription)")
                }
        }
}
//MARK: // L'ancienne propriété calculée 'accountDetailViewModel' qui retournait AccountDetailViewModel()
// est implicitement remplacée par l'utilisation de 'stockedAccountDetailViewModel'.
// Les vues qui ont besoin de AccountDetailViewModel utiliseront maintenant
// appViewModel.stockedAccountDetailViewModel (et géreront son optionalité).

//MARK: Changements importants : Contrairement à authentificationViewModel, AccountDetail et MoneyTransfer ViewModels deviennet de propriètés stockées et optionnelles.
//Le but : preserver leur état et leurs données  (le solde, les transactions, le destinataire en cours de saisie, etc.). S'ils seraient créées à chaque appel, toutes ces infos seraient perdues.
