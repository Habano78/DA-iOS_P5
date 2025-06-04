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

class AuthService: AuthenticationServiceProtocol {
        
        //MARK: Définition des propriétés d'instance dont la classe a besoin.
        private let urlSession: URLSession                  // Instance pour exécuter les requêtes HTTP.
        private let jsonEncoder: JSONEncoder                // Pour convertir les objets Swift en JSON
        private let jsonDecoder: JSONDecoder                // Pour convertir le JSON en objets Swift.
        
        init(urlSession: URLSession = .shared) {
                self.urlSession = urlSession
                self.jsonEncoder = JSONEncoder()
                self.jsonDecoder = JSONDecoder()
        }
        
        func login(credentials: AuthRequestDTO) async throws -> UserSession {
                //MARK: 1. Construction de l'URL complète pour l'endpoint "/auth".
                guard let baseURL = URL(string: baseURL.baseURLString),
                      var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        throw APIServiceError.invalidURL // Lance une erreur si l'URL de base est invalide.
                }
                components.path = "/auth" // Ajoute le chemin spécifique de l'endpoint.
                
                guard let url = components.url else {
                        throw APIServiceError.invalidURL // Lance une erreur si l'URL finale est invalide.
                }
                
                //MARK: 2. Création et configuration de l'objet URLRequest.
                var request = URLRequest(url: url)          // Crée la requête avec l'URL construite.
                request.httpMethod = "POST"                 // Définit la méthode HTTP sur POST.
                request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Indique que le corps est en JSON.
                
                //MARK: 3. Encodage des 'credentials' (AuthRequestDTO) en JSON pour le corps de la requête.
                do {
                        request.httpBody = try jsonEncoder.encode(credentials) // Tente d'encoder les données.
                } catch {
                        throw APIServiceError.requestEncodingFailed(error) // Lance une erreur si l'encodage échoue.
                }
                
                // Déclaration des variables pour stocker les données et la réponse de l'appel réseau.
                let data: Data
                let response: URLResponse
                
                // 4. Exécution de l'appel réseau asynchrone.
                do {
                        (data, response) = try await urlSession.data(for: request) // Effectue l'appel et attend la réponse.
                } catch {
                        throw APIServiceError.networkError(error) // Lance une erreur en cas de problème réseau.
                }
                
                // 5. Vérification de la réponse HTTP.
                guard let httpResponse = response as? HTTPURLResponse else { // S'assure que la réponse est bien une réponse HTTP.
                        throw APIServiceError.networkError(URLError(.badServerResponse)) // Lance une erreur si la réponse n'est pas HTTP.
                }
                
                // Vérifie si le code de statut HTTP est 200 (OK).
                guard httpResponse.statusCode == 200 else {
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { // Cas spécifique : identifiants incorrects.
                                throw APIServiceError.invalidCredentials
                        } else { // Autres codes d'erreur HTTP.
                                throw APIServiceError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
                
                // 6. Décodage de la réponse JSON en AuthResponseDTO.
                do {
                        let authResponseDTO = try jsonDecoder.decode(AuthResponseDTO.self, from: data) // Tente de décoder les données reçues.
                        // 7. Création et retour du modèle métier UserSession avec le token.
                        return UserSession(token: authResponseDTO.token)
                } catch {
                        throw APIServiceError.responseDecodingFailed(error)// Lance une erreur si le décodage échoue.
                }
        }
}
