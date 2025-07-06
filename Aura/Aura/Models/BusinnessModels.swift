//
//  BusinnessModels.swift
//  Aura
//
//  Created by Perez William on 30/05/2025.
//

import Foundation

// MARK: Représenter la session active de l'utilisateur au sein de l'application.
struct UserSession: Equatable {
        let token: String
}

//MARK: Ce modèle, derivé de TransactionDTO, représente une transaction individuelle telle que l'application la comprendra et l'utilisera.
struct Transaction: Identifiable, Hashable {
        let id: UUID
        let label: String
        let value: Decimal
        
        
        //MARK: Init (mapping)
        init (from dto: TransactionDTO) {
                self.id=UUID() // L'API ne fournit pas d'ID, donc nous en générons un côté client.
                self.value = dto.value
                self.label = dto.label
        }
        // Un autre initialiseur pour créer des instances de Transaction manuellement
        init (id: UUID=UUID(), value: Decimal, label: String) {
                self.id=id
                self.value = value
                self.label = label
        }
}

//MARK: Ce modèle représentera les informations du compte de l'utilisateur.
struct AccountDetails {
        let totalAmount: Decimal
        let transactions: [Transaction]
        
        //MARK: Mapping
        init(from dto: AccountDetailsDTO) {
                self.totalAmount = dto.currentBalance
                self.transactions = dto.transactions.map(Transaction.init)
        }
        
        //MARK: Init pour créer des instances d'AccountDetail manuellement
        // (utile pour les prévisualisations SwiftUI ou les tests)
        init(totalAmount: Decimal, transactions: [Transaction]) {
                self.totalAmount = totalAmount
                self.transactions = transactions
        }
}

//MARK: Informations nécessaires pour initier un transfert, telles qu'elles sont gérées ou validées au sein de l'application avant l'appel à l'API.
struct TransferRequestData {
        let recipient: String
        let amount: Decimal
}
 
// Question TransfeRequestData
