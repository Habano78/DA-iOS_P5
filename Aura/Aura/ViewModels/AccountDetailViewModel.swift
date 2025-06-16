//
//  AccountDetailViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

// On marque toute la classe avec @MainActor pour garantir que les mises à jour
// des propriétés @Published se font sur le thread principal.
@MainActor
class AccountDetailViewModel: ObservableObject {
        
        // Les propriétés sont initialisées à "zéro". Elles seron peuplées après l'appel à l'API.
        @Published var totalAmount: Decimal = 0.0
        @Published var recentTransactions: [Transaction] = []
        
        // Propriétés d'état pour le chargement et les erreurs
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        
        // Dépendances injectées
        private let accountService: AccountServiceProtocol
        private let userSession: UserSession
        
        init(accountService: AccountServiceProtocol, userSession: UserSession) {
                self.accountService = accountService
                self.userSession = userSession
        }
        
        // La méthode pour charger les détails du compte reste la même.
        func getAccountDetails() async {
                isLoading = true
                defer { isLoading = false }
                errorMessage = nil
                
                do {
                        let accountDetails = try await self.accountService.getAccountDetails(identifiant: self.userSession)
                        
                        // Met à jour les propriétés avec les données reçues de l'API.
                        self.totalAmount = accountDetails.totalAmount
                        self.recentTransactions = accountDetails.transactions
                        
                } catch let error as APIServiceError {
                        self.errorMessage = error.errorDescription
                } catch {
                        self.errorMessage = "Une erreur inattendue est survenue."
                }
        }
}


//MARK: Changes.
//1. Delete the struct Transaction {description:String,amount:String} because en contraduction with our business model Transaction.
//2. change on Transaction properties names : value/amount and label/description
//3. change in values type for Decimal
//4. change in totalAmount type from String to Decimal.
