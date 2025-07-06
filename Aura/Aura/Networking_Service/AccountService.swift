//
//  AccountService.swift
//  Aura
//
//  Created by Perez William on 30/05/2025.
//

import Foundation

protocol AccountServiceProtocol{
        @MainActor
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails
}

class AccountService: AccountServiceProtocol{
        
        //MARK: propriétés d'instance dont la classe a besoin.
        private let jsonDecoder: JSONDecoder
        private nonisolated let urlSession: URLSessionProtocol
        
        init(urlSession: URLSessionProtocol = URLSession.shared) {
                self.urlSession = urlSession
                self.jsonDecoder = JSONDecoder()
        }
        
        @MainActor
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails {
                
                // construction de l'URL final
                guard let baseURL = URL(string: baseURL.baseURLString) else {
                        throw APIServiceError.invalidURL
                }
                //ajout du chemin de l'endpoint (/account) à la baseURL
                var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
                components?.path = "/account"
                
                //validation de l'URL final (non-optionel)
                let finalUrlO = components?.url
                guard let finalURL = finalUrlO else {
                        throw APIServiceError.invalidURL
                }
                
                //MARK: création et configuration de URLRequest.
                var request = URLRequest(url: finalURL)
                request.httpMethod = "GET"
                request.setValue(identifiant.token, forHTTPHeaderField: "token")
                
                //MARK: appel réseau
                let data: Data
                let response: URLResponse
                
                do {
                        (data, response) = try await self.urlSession.data(for: request)
                } catch {
                        
                        throw APIServiceError.networkError(error)
                }
                
                //MARK: vérification de la Réponse HTTP.
                guard let httpResponse = response as? HTTPURLResponse else {
                        
                        throw APIServiceError.networkError(URLError(.badServerResponse))
                }
                guard httpResponse.statusCode == 200 else {
                        
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { /// 401: Non Autorisé, 403: Interdit
                                
                                throw APIServiceError.tokenInvalidOrExpired
                        } else {
                                /// Pour tous les autres codes de statut HTTP qui ne sont pas 200.
                                throw APIServiceError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
                
                //MARK: décodage de la Réponse JSON en DTO
                let accountDetailsDTO: AccountDetailsDTO
                
                do {
                        accountDetailsDTO = try self.jsonDecoder.decode(AccountDetailsDTO.self, from: data)
                        
                } catch {
                        
                        throw APIServiceError.responseDecodingFailed(error)
                }
                
                //MARK: mapping du DTO (accountDetailsDTO) en Modèle Métier (AccountDetails) et retour.
                let domainAccountDetails = AccountDetails(from: accountDetailsDTO)
                
                return domainAccountDetails
        }
}
