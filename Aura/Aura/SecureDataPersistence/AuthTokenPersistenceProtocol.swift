//
//  AuthTokenPersistenceProtocol.swift
//  Aura
//
//  Created by Perez William on 16/06/2025.
//

import Foundation

//MARK: ce protocole Définit le contrat pour tout objet capable de sauvegarder, récupérer et supprimer un token d'authentification.
protocol AuthTokenPersistenceProtocol {
        func saveToken(_ token: String) throws
        func retrieveToken() throws -> String?
        func deleteToken() throws
}
