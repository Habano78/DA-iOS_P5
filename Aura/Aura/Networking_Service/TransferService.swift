//
//  TransfertService.swift
//  Aura
//
//  Created by Perez William on 31/05/2025.
//

// Fichier: TransferService.swift

import Foundation

protocol TransferServiceProtocol {
       @MainActor
        func sendMoney(transferData: TransferRequestData, identifiant: UserSession) async throws
}

class TransferService: TransferServiceProtocol {
        private nonisolated let urlSession: URLSessionProtocol /// Permet d'appeler ses méthodes (qui s'exécutent en arrière-plan) depuis un contexte @MainActor sans avertissement de data race.
        private let jsonEncoder: JSONEncoderProtocol
        
        init(urlSession: URLSessionProtocol = URLSession.shared,
                 jsonEncoder: JSONEncoderProtocol = JSONEncoder()) {
                self.urlSession = urlSession
                self.jsonEncoder = jsonEncoder
            }
        @MainActor
        func sendMoney(transferData: TransferRequestData, identifiant: UserSession) async throws {
                
                // MARK: - Étape 1: Construction de l'URL
                // Identique à AccountService: construction de l'URL complète pour l'endpoint "/account/transfer".
                guard let resolvedBaseURL = URL(string: baseURL.baseURLString) else {
                        throw APIServiceError.invalidURL
                }
                var components = URLComponents(url: resolvedBaseURL, resolvingAgainstBaseURL: true)
                components?.path = "/account/transfer" // Endpoint spécifique pour le transfert.
                
                guard let url = components?.url else {
                        throw APIServiceError.invalidURL
                }
                
                // MARK: - Étape 2: Création et Configuration de URLRequest
                var request = URLRequest(url: url)
                // Méthode POST car nous envoyons des données pour créer une ressource/action.
                request.httpMethod = "POST"
                
                // Header d'authentification, comme pour AccountService.
                request.setValue(identifiant.token, forHTTPHeaderField: "token")
                // Différence clé : Spécifier que le corps de notre requête sera du JSON.
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // MARK: - Étape 3: Préparation et Encodage du Corps de la Requête
                // Cette étape est spécifique aux requêtes qui envoient des données (POST, PUT, etc.).
                // 1. Créer le DTO à partir des données métier.
                //    (Pour l'instant, TransfertRequestData et TransferRequestDTO ont la même structure,
                //     mais c'est une bonne pratique de distinguer le modèle de données interne du DTO)
                let requestDTO = TransferRequestDTO(recipient: transferData.recipient, amount: transferData.amount)
                
                // 2. Encoder le DTO en JSON.
                // On utilise un bloc do-catch pour l'opération d'encodage qui peut échouer.
                do {
                        // Ici on encode le DTO en JSON pour assigner le résultat au corps de la requête.
                        
                        request.httpBody = try self.jsonEncoder.encode(requestDTO)
                        
                } catch {
                        // Si l'encodage échoue, on lance une erreur.
                        throw APIServiceError.requestEncodingFailed(error)
                }
                
                // MARK: - Étape 4: Exécution de l'Appel Réseau
                // Identique à AccountService: envoi de la requête et attente de la réponse.
                // let data: Data // 'data' sera reçu mais potentiellement vide pour une réponse 200 OK. was never used; consider removing it
                let response: URLResponse
                do {
                        (_, response) = try await self.urlSession.data(for: request)
                } catch {
                        throw APIServiceError.networkError(error)
                }
                
                // MARK: - Étape 5: Vérification de la Réponse HTTP
                // Identique à AccountService pour la gestion des erreurs et du type de réponse.
                guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIServiceError.networkError(URLError(.badServerResponse))
                }
                // Différence clé : Pour cette API, un succès est juste un statut 200 avec un corps vide.
                // Pas de données à décoder en cas de succès.
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
