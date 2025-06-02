//
//  AppViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AppViewModel: ObservableObject {
        @Published var isLogged: Bool
        
        //MARK: Modifs
        /// Propriété ajoutée  pour stocker le UserSession. Optionnel, car nil si non connecté
        @Published var activeUserSession: UserSession?
        ///Instance d'un service qui se conforme à AuthenticationServiceProtocol et qui sera transmi a AuthViewModel
        private let monAuthService: AuthenticationServiceProtocol
        
        //MARK: init
        init() {
                self.isLogged = false
                self.monAuthService = AuthService() /// nouvelle instance de la classe concrète AuthService()
        }
        
        var authenticationViewModel: AuthenticationViewModel {
                return AuthenticationViewModel (
                        authService: self.monAuthService, 
                        onLoginSucceed: { [weak self] receivedUserSession in
                                self?.activeUserSession = receivedUserSession
                                self?.isLogged = true
                        }
                )
        }
        
        var accountDetailViewModel: AccountDetailViewModel {
                return AccountDetailViewModel()
        }
}
