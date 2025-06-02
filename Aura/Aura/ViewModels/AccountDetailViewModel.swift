//
//  AccountDetailViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AccountDetailViewModel: ObservableObject {
        
        @Published var totalAmount: Decimal = (12.34567)
        @Published var recentTransactions: [Transaction] = [
                Transaction(value: Decimal(-5.50), label: "Starbucks"),
                Transaction(value: Decimal(-34.99),label: "Amazon"),
                Transaction(value: Decimal(1200.00), label: "Salary")
        ]
        
        //MARK: Propriétés d'état pour le chargement et les erreurs
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        //MARK: Nouvelles propriétés pour injecter les dépendances
        private let accountService: AccountServiceProtocol
        private let userSession: UserSession
        
        init (accountService: AccountServiceProtocol, userSession: UserSession) {
                self.accountService = accountService
                self.userSession = userSession
        }
        
        //MARK: Méthode pour charger les détails du compte depuis l'API
        @MainActor ///Pour les mises à jour de l'UI
        func getAccountDetails() async {
                isLoading = true                // Indique que le chargement commence
                defer { isLoading = false }     // Garantit que isLoading sera false à la sortie de cette fonction
                errorMessage = nil              // Réinitialise les messages d'erreur précédents
                
                print("AccountDetailViewModel: Début de fetchAccountDetails...")
                
                do {
                        // Appelle la méthode du service pour obtenir les détails du compte.
                        // self.userSession est passé pour l'authentification.
                        //La constante accountDetails stocke le résultat du service (totalAmount + transactions[])
                        let accountDetails = try await self.accountService.getAccountDetails(identifiant: self.userSession)
                        
                        // Succès de l'appel au service !
                        // Met à jour les propriétés @Published du ViewModel avec les données reçues.
                        // Cela provoquera la mise à jour de la Vue SwiftUI.
                        self.totalAmount = accountDetails.totalAmount
                        self.recentTransactions = accountDetails.transactions
                        
                        print("AccountDetailViewModel: Détails du compte mis à jour. Nouveau solde: \(self.totalAmount)")
                        
                } catch let error as APIServiceError { /// Ici on attrape spécifiquement nos APIServiceError
                        /// Si une APIServiceError est lancée par le service (ex: .invalidURL, .networkError, .tokenInvalidOrExpired, etc.)
                        print("AccountDetailViewModel: Échec - APIServiceError: \(error.localizedDescription)")
                        /// on met à jour la propriété errorMessage avec la description localisée de notre enum APIServiceError.
                        /// la Vue pourra alors afficher ce message.
                        self.errorMessage = error.errorDescription
                        
                } catch {  ///Ici on attrape toute autre erreur inattendue
                        /// Ce bloc est une sécurité pour les erreurs qui ne seraient pas des APIServiceError (moins probable avec notre couche service en amount)
                        print("AccountDetailViewModel: Échec de la récupération des détails - Erreur inattendue: \(error.localizedDescription)")
                        self.errorMessage = "Une erreur inattendue est survenue lors de la récupération des détails de votre compte."
                }
        }
}


//MARK: Changes.
//1. Delete the struct Transaction {description:String,amount:String} because en contraduction with our business model Transaction.
//2. change on Transaction properties names : value/amount and label/description
//3. change in values type for Decimal
//4. change in totalAmount type from String to Decimal.
