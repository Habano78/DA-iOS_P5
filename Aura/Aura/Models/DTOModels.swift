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

//MARK: DTOs concernant la récuperation des détails du compte et la liste des transactions : GET /account.
/// GET. DTO qui représentera les champs d'une seule transaction.
struct TransactionDTO: Decodable, Hashable {
        let value: Decimal // correspond à la clé value du JSON
        let label: String// correspond à la clé label du JSON
}
///GET. Ce DTO va encapsuler les informations retournées par l'endpoint concernant les details du compte. GET/account
struct AccountDetailsDTO: Decodable {
        let currentBalance: Decimal
        let transactions: [TransactionDTO]
}

//MARK: DTO concernant la demande de transfert. Ce model a pour unique rôle de formater les données (recipient, amount) exactement comme l'API les attend pour initier un transfert. C'est un "paquet" que l'on prépare pour l'expédition.
///POST.. Initier un transfert d'argen
struct TransferRequestDTO: Encodable {
        let recipient: String //email ou phone
        let amount: Decimal
}
