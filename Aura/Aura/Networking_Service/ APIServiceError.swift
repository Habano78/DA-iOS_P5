//
//   APIServiceError.swift
//  Aura
//
//  Created by Perez William on 01/06/2025.
//

import Foundation

enum APIServiceError: Error, LocalizedError {
        // MARK: - Erreurs Techniques Communes
        
        /// Lancée si l'URL construite pour l'appel API est invalide.
        case invalidURL
        
        /// Lancée si l'encodage du corps de la requête en JSON échoue.
        /// L'erreur d'encodage originale est conservée.
        case requestEncodingFailed(Error)
        
        /// Lancée si le décodage de la réponse JSON du serveur échoue.
        /// L'erreur de décodage originale est conservée.
        case responseDecodingFailed(Error)
        
        /// Lancée pour les erreurs réseau de bas niveau (connectivité, timeout, DNS, etc.).
        /// L'erreur système originale (souvent une URLError) est conservée.
        case networkError(Error)
        
        /// Lancée si le serveur répond avec un code de statut HTTP inattendu
        /// qui n'est pas couvert par un cas plus spécifique ci-dessous. Le code est conservé.
        case unexpectedStatusCode(Int)
        
        // MARK: - Erreurs Sémantiques / Métier Communes (souvent liées aux codes 4xx)
        
        /// Lancée spécifiquement lors d'un échec de login à cause d'identifiants incorrects
        /// (typiquement une réponse HTTP 401 ou 403 sur l'endpoint /auth).
        case invalidCredentials
        
        /// Lancée lorsqu'une opération nécessitant un token échoue parce que le token est
        /// invalide, expiré ou non autorisé pour la ressource demandée
        /// (typiquement une réponse HTTP 401 ou 403 sur des endpoints comme /account ou /transfer).
        case tokenInvalidOrExpired
        
        // On pourrait ajouter d'autres cas communs ici si besoin, par exemple :
        // case resourceNotFound // Pour les erreurs HTTP 404
        // case serverError(Int) // Pour les erreurs HTTP 5xx génériques
        
        // MARK: - Descriptions Localisées
        var errorDescription: String? {
                switch self {
                        // Descriptions pour les erreurs techniques
                case .invalidURL:
                        return "L'URL de la requête API est invalide."
                case .requestEncodingFailed(let error):
                        return "Impossible de préparer les données pour l'envoi au serveur. Détail : \(error.localizedDescription)"
                case .responseDecodingFailed(let error):
                        return "Impossible de lire les données reçues du serveur. Détail : \(error.localizedDescription)"
                case .networkError(let error):
                        return "Un problème de réseau est survenu. Vérifiez votre connexion. Détail : \(error.localizedDescription)"
                case .unexpectedStatusCode(let statusCode):
                        return "Le serveur a répondu avec une erreur inattendue (Code: \(statusCode))."
                        
                        // Descriptions pour les erreurs métier
                case .invalidCredentials:
                        return "Nom d'utilisateur ou mot de passe incorrect."
                case .tokenInvalidOrExpired:
                        return "Votre session a peut-être expiré ou votre token n'est plus valide. Veuillez vous reconnecter."
                }
        }
}
