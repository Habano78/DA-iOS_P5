//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AuthenticationViewModel: ObservableObject {
        // Champs de texte de la Vue
        @Published var username: String = ""
        @Published var password: String = ""
        // Nouveau: États initial pour la Vue
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        
        //Nouvelle propriété pour stocker le service d'authentification.
        private let authService: AuthenticationServiceProtocol
        
        ///Modif: Maintenant, il prend un UserSession en paramètre
        let onLoginSucceed: ((UserSession) -> Void)
        
        init(authService: AuthenticationServiceProtocol, onLoginSucceed: @escaping (UserSession) -> Void) {
                self.authService = authService /// asignation du nouveau service passé en paramètre
                self.onLoginSucceed = onLoginSucceed
        }
        ///Modifs : 1.ajout async dans func; 2. init isLoading à true et de message à nil; 3; defer; 4.
        func login() async {
                isLoading = true
                defer { isLoading = false } ///Assure que isLoading est toujours remis à false
                errorMessage = nil
                
                ///nouveau// Instancie AuthRequestDTO avec les propriétés 'username' et 'password' du ViewModel saisies par l'utilisateur.
                let  loginCredentials  = AuthRequestDTO(username: self.username, password: self.password)
                
                //MARK: Appel au Service, gestion du succès et des erreurs
                do {
                        let userSession = try await authService.login(credentials: loginCredentials) /// Appeler la méthode login du service
                        print("AuthenticationViewModel: Connexion réussie via le service. Token: \(userSession.token.prefix(8))")
                        self.onLoginSucceed(userSession) /// // Exécute le callback pour signaler le succès à l'entité qui a créé ce ViewModel (AppViewModel)
                } catch let error as APIServiceError {
                        self.errorMessage = error.errorDescription
                }catch {
                        self.errorMessage = "Une erreur inattendue est survenue.Veuillez réessayer."
                }
                ///modif
                defer { isLoading = false } // Sera exécuté à la sortie de la fonction login()
                errorMessage = nil
        }
}
