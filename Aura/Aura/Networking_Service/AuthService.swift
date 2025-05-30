//
//  AuthenticationServiceProtocol.swift
//  Aura
//
//  Created by Perez William on 30/05/2025.
//

import Foundation

protocol AuthenticationServiceProtocol {
        /// Tente d'authentifier l'utilisateur avec les identifiants fournis.
        /// - Parameter credentials: Les informations d'identification (DTO de requête).
        /// - Returns: Une `UserSession` (modèle métier) en cas de succès.
        /// - Throws: Une erreur si l'authentification échoue ou si un problème réseau survient.
        func login(credentials: AuthRequestDTO) async throws -> UserSession
}
// Erreurs spécifiques à l'authentification
enum AuthenticationError: Error, LocalizedError {
        case invalidCredentials             // Pour les erreurs de type 401 ou 403
        case decodingFailed(Error)          // Erreur lors du décodage de la réponse
        case encodingFailed(Error)          // Erreur lors de l'encodage de la requête
        case invalidURL                     // Si l'URL de l'API est mal formée
        case networkError(Error)            // Erreur réseau générique (connectivité, timeout, etc.)
        case unexpectedStatusCode(Int)      // Si le serveur répond avec un code HTTP inattendu
        
        // Descriptions pour les erreurs, utile pour le débogage ou l'UI
        var errorDescription: String? {
                switch self {
                case .invalidCredentials:
                        return "Nom d'utilisateur ou mot de passe incorrect."
                case .decodingFailed(let error):
                        return "Échec du décodage de la réponse du serveur: \(error.localizedDescription)"
                case .encodingFailed(let error):
                        return "Échec de l'encodage de la requête: \(error.localizedDescription)"
                case .invalidURL:
                        return "L'URL de l'API est invalide."
                case .networkError(let error):
                        return "Erreur réseau: \(error.localizedDescription)"
                case .unexpectedStatusCode(let code):
                        return "Le serveur a répondu avec un statut inattendu: \(code)."
                }
        }
}

class AuthService: AuthenticationServiceProtocol {
        
        private let baseURLString = "http://127.0.0.1:8080" // Adresse de base pour tous les appels API.
        private let urlSession: URLSession                  // Instance pour exécuter les requêtes HTTP.
        private let jsonEncoder: JSONEncoder                // Outil pour convertir les objets Swift en JSON (pour les requêtes).
        private let jsonDecoder: JSONDecoder                // Outil pour convertir le JSON des réponses en objets Swift.
        
        init(urlSession: URLSession = .shared) {
                self.urlSession = urlSession
                self.jsonEncoder = JSONEncoder()
                self.jsonDecoder = JSONDecoder()
                // Configurations optionnelles pour l'encoder/decoder ici si besoin.
        }
        
        func login(credentials: AuthRequestDTO) async throws -> UserSession {
                // 1. Construction de l'URL complète pour l'endpoint "/auth".
                guard let baseURL = URL(string: baseURLString),
                      var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        throw AuthenticationError.invalidURL // Lance une erreur si l'URL de base est invalide.
                }
                components.path = "/auth" // Ajoute le chemin spécifique de l'endpoint.
                
                guard let url = components.url else {
                        throw AuthenticationError.invalidURL // Lance une erreur si l'URL finale est invalide.
                }
                
                // 2. Création et configuration de l'objet URLRequest.
                var request = URLRequest(url: url)          // Crée la requête avec l'URL construite.
                request.httpMethod = "POST"                 // Définit la méthode HTTP sur POST.
                request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Indique que le corps est en JSON.
                
                // 3. Encodage des 'credentials' (AuthRequestDTO) en JSON pour le corps de la requête.
                do {
                        request.httpBody = try jsonEncoder.encode(credentials) // Tente d'encoder les données.
                } catch {
                        throw AuthenticationError.encodingFailed(error) // Lance une erreur si l'encodage échoue.
                }
                
                // Déclaration des variables pour stocker les données et la réponse de l'appel réseau.
                let data: Data
                let response: URLResponse
                
                // 4. Exécution de l'appel réseau asynchrone.
                do {
                        (data, response) = try await urlSession.data(for: request) // Effectue l'appel et attend la réponse.
                } catch {
                        throw AuthenticationError.networkError(error) // Lance une erreur en cas de problème réseau.
                }
                
                // 5. Vérification de la réponse HTTP.
                guard let httpResponse = response as? HTTPURLResponse else { // S'assure que la réponse est bien une réponse HTTP.
                        throw AuthenticationError.networkError(URLError(.badServerResponse)) // Lance une erreur si la réponse n'est pas HTTP.
                }
                
                // Vérifie si le code de statut HTTP est 200 (OK).
                guard httpResponse.statusCode == 200 else {
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { // Cas spécifique : identifiants incorrects.
                                throw AuthenticationError.invalidCredentials
                        } else { // Autres codes d'erreur HTTP.
                                throw AuthenticationError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
                
                // 6. Décodage de la réponse JSON en AuthResponseDTO.
                do {
                        let authResponseDTO = try jsonDecoder.decode(AuthResponseDTO.self, from: data) // Tente de décoder les données reçues.
                        // 7. Création et retour du modèle métier UserSession avec le token.
                        return UserSession(token: authResponseDTO.token)
                } catch {
                        throw AuthenticationError.decodingFailed(error) // Lance une erreur si le décodage échoue.
                }
        }
}
