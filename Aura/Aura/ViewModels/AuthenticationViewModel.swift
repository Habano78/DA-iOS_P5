//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

@MainActor
class AuthenticationViewModel: ObservableObject {
        
        @Published var username: String = ""
        @Published var password: String = ""
        
        //MARK: État initial pour la Vue
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        
        //MARK: service d'authentification.
        private let authService: AuthenticationServiceProtocol
        
        //MARK: Callback
        let onLoginSucceed: ((UserSession) -> Void)
        
        init(authService: AuthenticationServiceProtocol, onLoginSucceed: @escaping (UserSession) -> Void) {
                self.authService = authService /// asignation du nouveau service passé en paramètre
                self.onLoginSucceed = onLoginSucceed
        }
        
        func login() async {
                isLoading = true
                defer { isLoading = false }
                errorMessage = nil
                
                //MARK: Préparation des données pour la requête
                let  loginCredentials  = AuthRequestDTO(username: self.username, password: self.password)
                
                //MARK: Appel au Service et gérer la réponse
                do {
                        let userSession = try await authService.login(credentials: loginCredentials)
                        print("AuthenticationViewModel: Connexion réussie via le service. Token: \(userSession.token.prefix(8))")
                        self.onLoginSucceed(userSession)
                } catch let error as APIServiceError {
                        self.errorMessage = error.errorDescription
                }catch {
                        self.errorMessage = "Erreur inattendue.Veuillez réessayer."
                }
        }
}
