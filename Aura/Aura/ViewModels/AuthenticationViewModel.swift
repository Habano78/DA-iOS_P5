//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AuthenticationViewModel: ObservableObject {
        
        @Published var username: String = ""
        @Published var password: String = ""
        
        // Nouveau: États initial pour la Vue
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        
        //Nouvelle propriété pour stocker le service d'authentification.
        private let authService: AuthenticationServiceProtocol
        
        ///Modif: Maintenant il prend un UserSession en paramètre
        let onLoginSucceed: ((UserSession) -> Void)
        
        init(authService: AuthenticationServiceProtocol, onLoginSucceed: @escaping (UserSession) -> Void) {
                self.authService = authService /// asignation du nouveau service passé en paramètre
                self.onLoginSucceed = onLoginSucceed
        }
        
        //MARK: ajout d'async
        func login() async {
                isLoading = true                        ///  Indiquer que le chargement commence
                defer { isLoading = false }      /// Garantir que isLoading sera false à la sortie de cette fonction
                errorMessage = nil                   ///Réinitialiser les messages d'erreur précédents
                
                //MARK: Préparer les données pour la requête
                ///Instancie AuthRequestDTO avec les propriétés 'username' et 'password' du ViewModel saisies par l'utilisateur.
                let  loginCredentials  = AuthRequestDTO(username: self.username, password: self.password)
                
                //MARK: Appel au Service et gérer la réponse
                do {
                        let userSession = try await authService.login(credentials: loginCredentials) /// Appeler la méthode login du service
                        print("AuthenticationViewModel: Connexion réussie via le service. Token: \(userSession.token.prefix(8))")
                        self.onLoginSucceed(userSession) /// // Exécute le callback pour signaler le succès à l'entité qui a créé ce ViewModel (AppViewModel)
                } catch let error as APIServiceError {
                        self.errorMessage = error.errorDescription
                }catch {
                        self.errorMessage = "Erreur inattendue.Veuillez réessayer."
                }
        }
}
