//
//   APIServiceError.swift
//  Aura
//
//  Created by Perez William on 01/06/2025.
//

import Foundation

// MARK: erreurs techniques Communes
enum APIServiceError: Error, LocalizedError, Equatable {
        case invalidURL /// si l'URL construite pour l'appel API est invalide.
        case requestEncodingFailed(Error)///  si l'encodage du corps de la requête en JSON échoue ('erreur originale conservée)
        case responseDecodingFailed(Error) /// si le décodage de la réponse JSON du serveur échoue.
        case networkError(Error) ///pour les erreurs réseau de bas niveau (connectivité, timeout, DNS, etc.).
        case unexpectedStatusCode(Int) ///si le serveur répond avec un code de statut HTTP inattendu
// MARK: erreurs sémantiques / Métier Communes (souvent liées aux codes 4xx)
        case invalidCredentials///lors d'un échec de login à cause d'identifiants incorrects(réponses HTTP 401 ou 403 sur l'endpoint /auth).
        case tokenInvalidOrExpired///lorsque le token est invalide, expiré ou non autorisé pour la ressource demandée
        
// MARK: descriptions localisées
        var errorDescription: String? {
                switch self {
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
                case .invalidCredentials:
                        return "Nom d'utilisateur ou mot de passe incorrect."
                case .tokenInvalidOrExpired:
                        return "Votre session a peut-être expiré ou votre token n'est plus valide. Veuillez vous reconnecter."
                }
        }
}

//MARK: Le protocole Error lui-même n'est pas Equatable. Swift ne sait donc pas comment comparer deux erreurs génériques pour savoir si elles sont égales.
extension APIServiceError {
        static func == (lhs: APIServiceError, rhs: APIServiceError) -> Bool {
                switch (lhs, rhs) {
                        // Pour les cas sans valeur associée, on vérifie juste si c'est le même cas.
                case (.invalidURL, .invalidURL):
                        return true
                case (.invalidCredentials, .invalidCredentials):
                        return true
                case (.tokenInvalidOrExpired, .tokenInvalidOrExpired):
                        return true
                        
                        // Pour les cas avec des valeurs associées 'Equatable' (comme Int), on compare les valeurs.
                case (.unexpectedStatusCode(let lhsCode), .unexpectedStatusCode(let rhsCode)):
                        return lhsCode == rhsCode
                        
                        // Pour les cas avec des valeurs associées non-'Equatable' (comme Error),
                        // on ne peut pas comparer les erreurs elles-mêmes (error1 == error2).
                        // Pour nos tests, il est souvent suffisant de considérer que si deux erreurs
                        // sont du même cas (par exemple, deux .networkError), elles sont "égales"
                        // pour la vérification du test.
                case (.requestEncodingFailed, .requestEncodingFailed):
                        return true
                case (.responseDecodingFailed, .responseDecodingFailed):
                        return true
                case (.networkError, .networkError):
                        return true
                        
                        // Si aucune des paires ci-dessus ne correspond, les erreurs ne sont pas égales.
                default:
                        return false
                }
        }
}
