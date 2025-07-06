//
//  AuthenticationServiceProtocol.swift
//  Aura
//
//  Created by Perez William on 30/05/2025.
//

import Foundation

protocol AuthenticationServiceProtocol {
        @MainActor
        func login(credentials: AuthRequestDTO) async throws -> UserSession
}

class AuthService: AuthenticationServiceProtocol {
        
        //MARK: 
        private nonisolated let urlSession: URLSessionProtocol
        
        private let jsonEncoder: JSONEncoder
        private let jsonDecoder: JSONDecoder
        
        init(urlSession: URLSessionProtocol = URLSession.shared) {
                self.urlSession = urlSession
                self.jsonEncoder = JSONEncoder()
                self.jsonDecoder = JSONDecoder()
        }
        
        func login(credentials: AuthRequestDTO) async throws -> UserSession {
                //MARK: construction de l'URL complète pour l'endpoint "/auth".
                guard let baseURL = URL(string: baseURL.baseURLString),
                      var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        throw APIServiceError.invalidURL // Lance une erreur si l'URL de base est invalide.
                }
                components.path = "/auth"
                
                guard let url = components.url else {
                        throw APIServiceError.invalidURL
                }
                
                //MARK: création et configuration de l'objet URLRequest.
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                //MARK: encodage des 'credentials' (AuthRequestDTO) en JSON pour le corps de la requête.
                do {
                        request.httpBody = try jsonEncoder.encode(credentials)
                } catch {
                        throw APIServiceError.requestEncodingFailed(error)
                }
                
                //MARK: stockage des données et de la réponse de l'appel réseau.
                let data: Data
                let response: URLResponse
                
                //MARK: exécution de l'appel réseau (asynchrone)
                do {
                        (data, response) = try await urlSession.data(for: request)
                } catch {
                        throw APIServiceError.networkError(error) // Lance une erreur en cas de problème réseau.
                }
                
                //MARK: vérification de la réponse HTTP.
                guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIServiceError.networkError(URLError(.badServerResponse))
                }
                
                //MARK: vérification de si le code de statut HTTP est 200 (OK)
                guard httpResponse.statusCode == 200 else {
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                                throw APIServiceError.invalidCredentials
                        } else {
                                throw APIServiceError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
                //MARK: décodage de la réponse JSON en AuthResponseDTO.
                do {
                        let authResponseDTO = try jsonDecoder.decode(AuthResponseDTO.self, from: data)
                        
                        //MARK: création et retour du modèle métier UserSession avec le token.
                        return UserSession(token: authResponseDTO.token)
                } catch {
                        throw APIServiceError.responseDecodingFailed(error)
                }
        }
}
