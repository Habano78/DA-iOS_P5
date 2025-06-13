//
//  MockAuthService.swift
//  Aura
//
//  Created by Perez William on 12/06/2025.
//

import Foundation
@testable import Aura // Pour accéder aux types

// Ce mock se conforme au contrat AuthenticationServiceProtocol
// et nous permet de dicter le résultat de l'appel à login.
class MockAuthService: AuthenticationServiceProtocol {

    // On peut configurer ce mock pour qu'il retourne un succès ou une erreur.
    var loginResult: Result<UserSession, APIServiceError>

    // On peut ajouter des "espions" pour vérifier si la méthode a été appelée.
    var loginCallCount = 0
    var receivedCredentials: AuthRequestDTO?

    // Initialiseur pour définir le comportement du mock pour un test donné.
    init(result: Result<UserSession, APIServiceError>) {
        self.loginResult = result
    }

    func login(credentials: AuthRequestDTO) async throws -> UserSession {
        // Quand la méthode login est appelée :
        loginCallCount += 1               // On incrémente le compteur d'appels.
        receivedCredentials = credentials // On sauvegarde les credentials reçus pour vérification.

        // On retourne le résultat prédéfini (soit le UserSession, soit l'erreur).
        return try loginResult.get()
    }
}
