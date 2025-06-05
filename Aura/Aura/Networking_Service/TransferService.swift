//
//  TransfertService.swift
//  Aura
//
//  Created by Perez William on 31/05/2025.
//

// Fichier: TransferService.swift

import Foundation

protocol TransferServiceProtocol {
        /// Tente d'exécuter un transfert d'argent.
        /// - Parameters:
        ///   - transferData: Les détails du transfert à effectuer (modèle de données interne).
        ///   - identifiant: La session utilisateur contenant le token d'authentification.
        /// - Throws: Une `APIServiceError` en cas d'échec.
        ///           Ne retourne rien (Void) en cas de succès, la confirmation vient du statut HTTP.
        func sendMoney(transferData: TransfertRequestData, identifiant: UserSession) async throws
}

class TransferService: TransferServiceProtocol {
        private let urlSession: URLSession                   // Instance pour exécuter les requêtes HTTP.
        private let jsonEncoder: JSONEncoder                 // Outil pour convertir les objets Swift en JSON pour le corps des requêtes.
        // Pas de jsonDecoder nécessaire ici pour le chemin de succès (réponse vide).
        
        init(urlSession: URLSession = .shared) {
                self.urlSession = urlSession
                self.jsonEncoder = JSONEncoder()
                // Configurations pour jsonEncoder si besoin (ex: stratégies de clés/dates).
                // Pour TransferRequestDTO, la configuration par défaut devrait suffire.
        }
        
        func sendMoney(transferData: TransfertRequestData, identifiant: UserSession) async throws {
                
                // MARK: - Étape 1: Construction de l'URL
                // Identique à AccountService: construction de l'URL complète pour l'endpoint "/account/transfer".
                guard let baseURL = URL(string: baseURL.baseURLString) else {
                        print("TransferService: Erreur critique - baseURLString est invalide: \(baseURL.baseURLString)")
                        throw APIServiceError.invalidURL
                }
                var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
                components?.path = "/account/transfer" // Endpoint spécifique pour le transfert.
                
                guard let url = components?.url else {
                        print("TransferService: Erreur critique - Impossible de construire l'URL pour /account/transfer")
                        throw APIServiceError.invalidURL
                }
                
                print("TransferService: URL construite pour POST /account/transfer: \(url.absoluteString)")
                
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
                do {
                        request.httpBody = try self.jsonEncoder.encode(requestDTO)
                        print("TransferService: Corps de la requête encodé avec succès.")
                } catch {
                        print("TransferService: Échec de l'encodage de TransferRequestDTO: \(error)")
                        throw APIServiceError.requestEncodingFailed(error)
                }
                
                // MARK: - Étape 4: Exécution de l'Appel Réseau
                // Identique à AccountService: envoi de la requête et attente de la réponse.
                let data: Data // 'data' sera reçu mais potentiellement vide pour une réponse 200 OK. was never used; consider removing it
                let response: URLResponse
                do {
                        (_, response) = try await self.urlSession.data(for: request)
                        print("TransferService: Réponse reçue du serveur.")
                } catch {
                        print("TransferService: Erreur réseau brute lors de l'appel à \(url.absoluteString): \(error.localizedDescription)")
                        throw APIServiceError.networkError(error)
                }
                
                // MARK: - Étape 5: Vérification de la Réponse HTTP
                // Identique à AccountService pour la gestion des erreurs et du type de réponse.
                guard let httpResponse = response as? HTTPURLResponse else {
                        print("TransferService: La réponse reçue n'est pas une réponse HTTP valide.")
                        throw APIServiceError.networkError(URLError(.badServerResponse))
                }
                
                print("TransferService: Code de statut HTTP reçu: \(httpResponse.statusCode)")
                
                // Différence clé : Pour cette API, un succès est juste un statut 200 avec un corps vide.
                // Pas de données à décoder en cas de succès.
                guard httpResponse.statusCode == 200 else {
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                                print("TransferService: Erreur d'authentification/autorisation (statut \(httpResponse.statusCode)).")
                                throw APIServiceError.tokenInvalidOrExpired
                        }
                        // On pourrait ajouter ici la gestion d'autres codes d'erreur spécifiques au transfert
                        // si l'API les documentait (ex: 400 Bad Request pour "fonds insuffisants" ou "destinataire invalide").
                        // Pour l'instant, on les traite comme des erreurs inattendues.
                        else {
                                print("TransferService: Erreur - Statut HTTP inattendu: \(httpResponse.statusCode).")
                                // Note: La 'data' reçue avec un code d'erreur pourrait contenir un message JSON du serveur.
                                // On pourrait essayer de le décoder ici si on avait un DTO d'erreur standard.
                                // Pour l'instant, notre APIServiceError.unexpectedStatusCode ne prend que le code.
                                // Si APIServiceError.unexpectedStatusCode(Int, Data?) était défini, on pourrait passer 'data'.
                                throw APIServiceError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
                
                // MARK: - Étape 6: Succès (Retour implicite de Void)
                // Si nous arrivons ici, statusCode == 200. L'API dit que la réponse est vide.
                // La fonction est 'throws' mais ne retourne rien explicitement (Void).
                // Atteindre ce point sans erreur signifie succès.
                print("TransferService: Transfert exécuté avec succès (statut 200).")
                // Pas de 'return' explicite nécessaire pour une fonction retournant Void.
        }
}
