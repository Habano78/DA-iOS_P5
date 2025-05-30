//
//  DTOModels.swift
//  Aura
//
//  Created by Perez William on 30/05/2025.
//

import Foundation

//MARK: DTOs Concernant l'authentification.
///POST. L'application doit envoyer un corps de requête JSON. Encodable pour transformer les données de la requete en JSON.
struct AuthRequestDTO: Encodable {
        let username: String
        let password: String
}
///GET. Le backend répond avec un JSON contenant un token type String(UUID).
struct AuthResponseDTO: Decodable {
        let token: String
}

//MARK: L'endpoint nous permettra de récupérer les détails du compte et la liste des transactions : GET /account.
/// DTO qui représentera les champs d'une seule transaction.
struct TansactionDTO: Decodable, Hashable {
        let value: Decimal // correspond à la clé value du JSON
        let label: String// correspond à la clé label du JSON
}
///Ce DTO va encapsuler l'ensemble des informations retournées par l'endpoint GET /account. C'est la réponse globale de GET/account
struct AccountDetailsDTO: Decodable {
        let currentBalance: Decimal
        let transactions: [TansactionDTO]
}

//MARK: POST /account/transfer: pour demander un transfert, l'application doit envoyer un corps de requête JSON
struct TransferRequestDTO: Encodable {
        let recipient: String //email ou phone
        let amount: Decimal
}
