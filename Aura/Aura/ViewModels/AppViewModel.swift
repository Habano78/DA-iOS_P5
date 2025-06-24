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
        
        // MARK: - Propriétés d'État
        
        @Published var isLogged: Bool
        @Published var activeUserSession: UserSession?
        
        @Published var stockedAccountDetailViewModel: AccountDetailViewModel?
        @Published var stockedMoneyTransferViewModel: MoneyTransferViewModel?
        
        // MARK: Dépendances (Services & Persistance)
        private let authService: AuthenticationServiceProtocol
        private let accountService: AccountServiceProtocol
        private let transferService: TransferServiceProtocol
        private let authTokenPersistence: AuthTokenPersistenceProtocol
        
        // MARK: Init
        init(
                authService: AuthenticationServiceProtocol = AuthService(),
                accountService: AccountServiceProtocol = AccountService(),
                transferService: TransferServiceProtocol = TransferService(),
                authTokenPersistence: AuthTokenPersistenceProtocol = AuthTokenPersistence()
        ) {
                // Initialisation des dépendances
                self.authService = authService
                self.accountService = accountService
                self.transferService = transferService
                self.authTokenPersistence = authTokenPersistence
                
                // Initialisation de l'état
                self.isLogged = false
                
                // Tâche asynchrone pour tenter de récupérer un token existant au démarrage
                Task {
                        await self.tryAutoLogin()
                }
        }
        
        // MARK: Propriété calculée - ViewModels Enfants
        var authenticationViewModel: AuthenticationViewModel {
                return AuthenticationViewModel (///CRÉE LA NOUVELLE INSTANCE
                        authService: self.authService,
                        onLoginSucceed: { [weak self] receivedUserSession in
                                self?.handleLoginSuccess(for: receivedUserSession)///ici  fournit le code du callback pour gérer le succès
                        }
                )
        }
        
        // MARK: - Pour gérer la logique commune après un succès de connexion
        func handleLoginSuccess(for session: UserSession) {
                print("AppViewModel: Succès de connexion.")
                /// Sauvegarde du token dans le Keychain
                do {
                        try self.authTokenPersistence.saveToken(session.token)
                        //print("AppViewModel: Token sauvegardé dans le Keychain.")
                } catch {
                        print("AppViewModel: ERREUR lors de la sauvegarde du token: \(error.localizedDescription)")
                }
                
                /// Mise à jour de l'état global de l'application
                self.activeUserSession = session
                self.isLogged = true
                
                /// Callback pour la gestion de l'expiration de session. On utilise [unowned self] pour garantir que la référence ne sera pas nil dans les contextes où l'on sait que AppViewModel doit exister.
                let sessionExpiredCallback = { [unowned self] in
                        print("AppViewModel: Callback onSessionExpired reçu, déconnexion en cours...")
                        self.logout()
                }
                
                ///s Création des ViewModels pour la session connectée
                self.stockedAccountDetailViewModel = AccountDetailViewModel(
                        accountService: self.accountService,
                        userSession: session,
                        onSessionExpired: sessionExpiredCallback
                )
                self.stockedMoneyTransferViewModel = MoneyTransferViewModel(
                        transferService: self.transferService,
                        userSession: session
                )
        }
        
        //MARK: méthode pour tenter de connecter l'utilisateur automatiquement au démarrage de l'app.
        private func tryAutoLogin() async {
                print("AppViewModel: Tentative de récupération du token existant...")
                do {
                        if let retrievedToken = try self.authTokenPersistence.retrieveToken(), !retrievedToken.isEmpty {
                                let session = UserSession(token: retrievedToken)
                                self.handleLoginSuccess(for: session)
                        } else {
                                print("AppViewModel: Aucun token valide trouvé pour l'auto-connexion.")
                        }
                } catch {
                        print("AppViewModel: ERREUR lors de la récupération du token depuis le Keychain: \(error.localizedDescription)")
                }
        }
        
        //MARK: Gère la déconnexion à la démande de l'utilisateur.
        func logout() {
                do {
                        try self.authTokenPersistence.deleteToken()
                } catch {
                        print("AppViewModel: ERREUR lors de la suppression du token: \(error.localizedDescription)")
                }
                
                //MARK: Réinitialisation de l'état de l'application
                self.isLogged = false
                self.activeUserSession = nil
                self.stockedAccountDetailViewModel = nil
                self.stockedMoneyTransferViewModel = nil
        }
}


//MARK: MODIFICATIONS L'ancienne propriété calculée 'accountDetailViewModel' qui retournait AccountDetailViewModel()
// est implicitement remplacée par l'utilisation de 'stockedAccountDetailViewModel'.
// Les vues qui ont besoin de AccountDetailViewModel utiliseront maintenant
// appViewModel.stockedAccountDetailViewModel (et géreront son optionalité).

//MARK: Changements importants : Contrairement à authentificationViewModel, AccountDetail et MoneyTransfer ViewModels deviennet de propriètés stockées et optionnelles.
//Le but : preserver leur état et leurs données  (le solde, les transactions, le destinataire en cours de saisie, etc.). S'ils seraient créées à chaque appel, toutes ces infos seraient perdues.
