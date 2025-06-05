//
//  TokenAuthWrapperStore.swift
//  Aura
//
//  Created by Perez William on 04/06/2025.
//

// AuthTokenStore.swift (votre version)
import Foundation
import Security

class AuthTokenPersistence {
    private let keychainService: KeychainInterface ///Dépendance au protocole
    private let tokenLabel = "com.aura.authToken" ///Clé unique et constante pour le token

    init(keychainService: KeychainInterface = KeychainService()) { ///. Injection de dépendance avec valeur par défaut
        self.keychainService = keychainService
    }

    func saveToken(_ token: String) throws { //Bonne signature
        guard let tokenData = token.data(using: .utf8) else { //Conversion String -> Data sécurisée
            struct TokenConversionError: Error {} //Erreur locale spécifique, c'est propre
            throw TokenConversionError()
        }
        ///Préparation des attributs pour le Keychain
        let attributes: [String: Any] = [kSecValueData as String: tokenData]
        try keychainService.save(label: tokenLabel, attributes: attributes) // Appel au service
    }

    func retrieveToken() throws -> String? {
        do {
            let item = try keychainService.retrieve(label: tokenLabel)
            /// Extraction et conversion sécurisées des données
            guard let tokenData = item[kSecValueData as String] as? Data,
                  let tokenString = String(data: tokenData, encoding: .utf8) else {
                ///Lancement d'une erreur si les données ne sont pas au format attendu
                throw KeychainService.KeychainError.unexpectedData
            }
            return tokenString ///Retourne le token
        } catch KeychainService.KeychainError.itemNotFound {
                //Gestion du cas "non trouvé" : ce n'est pas une erreur à propager,
                // mais l'absence de token, donc on retourne nil.
                return nil
        }
    }

    func deleteToken() throws {
        try keychainService.delete(label: tokenLabel)
    }
}
