//
//  AppViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

// AppViewModel.swift
import Foundation

class AppViewModel: ObservableObject {
        @Published var isLogged: Bool
        /// Propriété ajoutée  pour stocker le UserSession. Optionnel, car nil si non connecté
        @Published var activeUserSession: UserSession?
        
        //MARK: Changements importants : Contrairement à authentificationViewModel, AccountDetail et MoneyTransfer ViewModels deviennet de propriètés stockées et optionnelles. Le but de les déclarer ici est de les avoir
        @Published private(set) var stockedAccountDetailViewModel: AccountDetailViewModel?
        @Published private(set) var stockedMoneyTransferViewModel: MoneyTransfertViewModel?
        
        //MARK: nouvelles propriétés d'instance qu'AppViewModel doit transmettre au correspondants viewmodels
        private let authService: AuthenticationServiceProtocol
        private let accountService: AccountServiceProtocol
        private let transferService: TransferServiceProtocol
        
        //MARK: init
        init() {
                self.isLogged = false
                self.authService = AuthService()
                self.accountService = AccountService()
                self.transferService = TransfertService()
        }
        
        // authenticationViewModel reste une propriété calculée, ce qui est acceptable
        // pour un écran de login qui peut être recréé si besoin.
        var authenticationViewModel: AuthenticationViewModel {
                return AuthenticationViewModel (
                        authService: self.authService,
                        onLoginSucceed: { [weak self] receivedUserSession in
                                //Capture faible
                                guard let self = self else { return }
                                
                                self.activeUserSession = receivedUserSession
                                self.isLogged = true
                                
                                //Création et assignation de AccountDetailViewModel ici.
                                ///  créé une seule fois et uniquement après une connexion réussie.
                                self.stockedAccountDetailViewModel = AccountDetailViewModel(
                                        accountService: self.accountService,
                                        userSession: receivedUserSession // On passe la session reçue
                                )
                                
                                self.stockedMoneyTransferViewModel = MoneyTransferViewModel(
                                        transferService: self.transferService,
                                        userSession: receivedUserSession
                                )
                        }
                )
        }
        //MARK: cette fonction peut-être activée par un geste de l'utilisateur "DECONEXION"
        func logout() {
                self.isLogged = false
                self.activeUserSession = nil
                self.stockedAccountDetailViewModel = nil
                self.stockedAccountDetailViewModel = nil
        }
}
//MARK: // L'ancienne propriété calculée 'accountDetailViewModel' qui retournait AccountDetailViewModel()
// est implicitement remplacée par l'utilisation de 'stockedAccountDetailViewModel'.
// Les vues qui ont besoin de AccountDetailViewModel utiliseront maintenant
// appViewModel.stockedAccountDetailViewModel (et géreront son optionalité).
