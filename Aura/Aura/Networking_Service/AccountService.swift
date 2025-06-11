//
//  AccountService.swift
//  Aura
//
//  Created by Perez William on 30/05/2025.
//

import Foundation

protocol AccountServiceProtocol{
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails
}

class AccountService: AccountServiceProtocol{
        
        //MARK: Définition des propriétés d'instance dont la classe a besoin.
        private let jsonDecoder: JSONDecoder
        private let urlSession: URLSessionProtocol
        
        init(urlSession: URLSessionProtocol = URLSession.shared) {
                self.urlSession = urlSession // Assigne l'instance de URLSession (injectée ou par défaut)
                self.jsonDecoder = JSONDecoder() // Crée une nouvelle instance de JSONDecoder par défaut
        }
        
        //MARK: Implémentation de la méthode getAccountDetails 
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails {
               
                //MARK: 1. Construction de l'URL final finalURL
                ///1.1. On tente de créer un objet URL à partir de notre baseURLString (chaine).
                /// Cet initialiseur retourne un URL? (un optionnel), car la chaîne pourrait être mal formée.
                guard let baseURL = URL(string: baseURL.baseURLString) else {
                        print("AccountService: Erreur critique - baseURLString est invalide: \(baseURL.baseURLString)") // Pour le débogage
                        throw APIServiceError.invalidURL // On arrête la fonction et on lance notre erreur spécifique.
                }
                print("AccountService: baseURL construite avec succès: \(baseURL.absoluteString)")
                ///1.2. Ajouter le chemin de l'endpoint (/account) à la baseURL
                /// On crée une variable components et on initialise URLComponents en lui passant notre baseURL
                var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
                components?.path = "/account"
                //1.3. URL final et validité
                /// tente de récupérer l'objet URL final (optionnel) depuis les composants.
                let finalUrlO = components?.url
                ///Le guard vérifie si finalUrlO (l'optionnel) contient une valeur non-nil.
                guard let finalURL = finalUrlO else {
                        print("AccountService: Erreur critique - components est invalide")
                        throw APIServiceError.invalidURL
                }/// À ce stade, finalURL est un URL valide et non-optionnel.
                
                //MARK: Étape 2 : Création et configuration de URLRequest.  Cet objet contiendra tous les détails de la requête que nous allons envoyer (la méthode HTTP, les en-têtes, et potentiellement un corps, bien que ce ne soit pas le cas pour un GET)
                
                var request = URLRequest(url: finalURL) /// instance de URLRequest avec l'URL de destination.
                request.httpMethod = "GET" /// La méthode HTTP de request est un  GET : recuperer des données
                request.setValue(identifiant.token, forHTTPHeaderField: "token") /// Ajoute le token d'authentification dans les en-têtes HTTP de la requête.
                ///C'est ainsi que nous attachons le jeton d'authentification à notre requête pour que le serveur puisse vérifier que nous avons le droit d'accéder à l'endpoint /account. Sans ce header (ou avec un token incorrect), le serveur nous renverrait probablement une erreur (comme un code HTTP 401 "Non autorisé" ou 403 "Interdit").
                // À ce stade, 'request' est notre URLRequest prête pour GET /account,
                // configurée avec la méthode GET et le header 'token'.
                
                //MARK: Étape 3 : Exécution de l'appel réseau : envoyer la requête et de capturer soit les données et la réponse, soit une erreur réseau.
                
                ///Déclaration des constantes pour stocker les données brutes et les informations de la réponse.
                ///Elles seront initialisées dans le bloc 'do' ci-dessous.
                let data: Data
                let response: URLResponse
                
                /// Execution de l'appel réseau.
                /// 'await' car c'est une opération asynchrone. 'try' car cette méthode peut lancer une erreur
                do {
                        (data, response) = try await self.urlSession.data(for: request)
                } catch {
                        /// Si une erreur est lancée par urlSession.data(for:), on l'attrape ici.
                        /// On enveloppe l'erreur système originale dans notre type d'erreur personnalisé.
                        throw APIServiceError.networkError(error)
                }
                
                //MARK: Étape 4 : Vérification de la Réponse HTTP.
                // Tente de convertir (caster) la URLResponse générique en une HTTPURLResponse plus spécifique.
                // Cela nous donne accès à des informations HTTP comme le code de statut.
                guard let httpResponse = response as? HTTPURLResponse else {
                        // Si le cast échoue, la réponse n'est pas une réponse HTTP standard, ce qui est inattendu.
                        print("AccountService: La réponse reçue n'est pas une réponse HTTP valide.")
                        // On lance une erreur réseau, car c'est un problème fondamental avec la réponse du serveur.
                        throw APIServiceError.networkError(URLError(.badServerResponse))
                }
                
                // Affiche le code de statut HTTP reçu pour le débogage.
                print("AccountService: Code de statut HTTP reçu: \(httpResponse.statusCode)")
                
                // Vérifie si le code de statut indique un succès. Pour un GET qui retourne des données,
                // le code de succès standard est 200 (OK).
                guard httpResponse.statusCode == 200 else {
                        // Si le code de statut n'est pas 200, il y a une erreur.
                        // On vérifie s'il s'agit d'une erreur d'authentification/autorisation connue.
                        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { // 401: Non Autorisé, 403: Interdit
                                print("AccountService: Erreur d'authentification ou d'autorisation (statut \(httpResponse.statusCode)). Token pourrait être invalide.")
                                throw APIServiceError.tokenInvalidOrExpired
                        } else {
                                // Pour tous les autres codes de statut HTTP qui ne sont pas 200.
                                print("AccountService: Erreur - Statut HTTP inattendu: \(httpResponse.statusCode).")
                                throw APIServiceError.unexpectedStatusCode(httpResponse.statusCode)
                        }
                }
                
                //MARK: Étape 5 : Décodage de la Réponse JSON en DTO
                /// le but  ici est de transformer les données JSON brutes (contenues dans data) en une instance de notre AccountDetailsDTO.
                
                let accountDetailsDTO: AccountDetailsDTO
                
                do {
                        // On utilise l'instance 'jsonDecoder' (propriété de notre classe AccountService)
                        // pour tenter de convertir les 'data' JSON en un objet de type AccountDetailsDTO.
                        // 'AccountDetailsDTO.self' indique au décodeur le type exact que nous attendons.
                        // 'try' est utilisé car la méthode 'decode' peut lancer une erreur si les 'data'
                        // ne correspondent pas à la structure de AccountDetailsDTO (ex: champ manquant, type incorrect).
                        accountDetailsDTO = try self.jsonDecoder.decode(AccountDetailsDTO.self, from: data)
                        
                        // Si nous arrivons ici, le décodage a réussi.
                        print("AccountService: AccountDetailsDTO décodé avec succès. Solde DTO: \(accountDetailsDTO.currentBalance)")
                        
                } catch {
                        // Si 'jsonDecoder.decode(...)' lance une erreur (typiquement une DecodingError),
                        // l'erreur est attrapée ici. 'error' contient l'erreur de décodage originale.
                        print("AccountService: Échec du décodage de AccountDetailsDTO: \(error)") // Affiche l'erreur technique
                        // Nous enveloppons l'erreur de décodage originale dans notre type d'erreur personnalisé
                        // et nous la relançons pour que le ViewModel puisse la traiter.
                        throw APIServiceError.responseDecodingFailed(error)
                } // À ce stade, 'accountDetailsDTO' contient les données du compte sous forme de DTO.
                
                //MARK: 6. Mapping du DTO (accountDetailsDTO) en Modèle Métier (AccountDetails) et retour.
                
                // Cet initialiseur s'occupe de la transformation, y compris le mapping
                // de 'dto.currentBalance' vers 'totalAmount' (si vous avez fait ce changement dans le modèle métier)
                // et la conversion de chaque 'TransactionDTO' en 'Transaction' (modèle métier).
                let domainAccountDetails = AccountDetails(from: accountDetailsDTO)
                
                print("AccountService: Mapping de DTO vers AccountDetails (modèle métier) réussi.")
                
                // Retourne l'objet AccountDetails (modèle métier) qui est maintenant prêt
                // à être utilisé par le ViewModel ou une autre partie de l'application.
                return domainAccountDetails // (B)
        }
}
