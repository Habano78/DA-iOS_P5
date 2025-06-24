//
//  TransfertService.swift
//  Aura
//
//  Created by Perez William on 31/05/2025.
//
import Foundation

protocol TransferServiceProtocol {
        @MainActor
        func sendMoney(transferData: TransferRequestData, identifiant: UserSession) async throws
}


class TransferService: TransferServiceProtocol {
        //MARK: nonisolated permet à (la dépendence) URLSession de travailler en sécurité en arrière-plan; on evite ainsi les warnings de date race
        private nonisolated let urlSession: URLSessionProtocol
        
        private let jsonEncoder: JSONEncoderProtocol
        
        init(urlSession: URLSessionProtocol = URLSession.shared,
             jsonEncoder: JSONEncoderProtocol = JSONEncoder()) {
                self.urlSession = urlSession
                self.jsonEncoder = jsonEncoder
        }
        @MainActor
        func sendMoney(transferData: TransferRequestData, identifiant: UserSession) async throws {
                
                // MARK: construction de l'URL
                guard let resolvedBaseURL = URL(string: baseURL.baseURLString) else {
                        throw APIServiceError.invalidURL
                }
                //MARK: configuration du Endpoint pour le transfert.
                var components = URLComponents(url: resolvedBaseURL, resolvingAgainstBaseURL: true)
                components?.path = "/account/transfer"
                guard let url = components?.url else {
                        throw APIServiceError.invalidURL
                }
                // MARK: création et Configuration de URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(identifiant.token, forHTTPHeaderField: "token")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // MARK: préparation et Encodage du Corps de la Requête
                let requestDTO = TransferRequestDTO(recipient: transferData.recipient, amount: transferData.amount)
                
                do {
                        request.httpBody = try self.jsonEncoder.encode(requestDTO)
                        
                } catch {
                        throw APIServiceError.requestEncodingFailed(error)
                }
                
                // MARK: Appel Réseau
                let response: URLResponse
                do {
                        (_, response) = try await self.urlSession.data(for: request)
                } catch {
                        throw APIServiceError.networkError(error)
                }
                
                // MARK: vérification de la Réponse HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIServiceError.networkError(URLError(.badServerResponse))
                }
                //MARK: différence clé : Pour cette API, un succès est juste un statut 200 avec un corps vide.
                guard httpResponse.statusCode == 200 else {
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                                
                                throw APIServiceError.tokenInvalidOrExpired
                        }
                        else {
                                throw APIServiceError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
        }
}
