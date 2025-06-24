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
        
        //MARK:  Propriétés
        @Published var totalAmount: Decimal = 0.0
        @Published var recentTransactions: [Transaction] = []
        
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        
        //MARK:  Dépendances injectées
        private let accountService: AccountServiceProtocol
        private let userSession: UserSession
        private let onSessionExpired: () -> Void
        
        //MARK: Init
        init(
                accountService: AccountServiceProtocol,
                userSession: UserSession,
                onSessionExpired: @escaping () -> Void
        ) {
                self.accountService = accountService
                self.userSession = userSession
                self.onSessionExpired = onSessionExpired
        }
        
        //MARK: appel à la méthode pour charger les détails du compte
        func getAccountDetails() async {
                isLoading = true
                defer { isLoading = false }
                errorMessage = nil
                
                do {
                        let accountDetails = try await self.accountService.getAccountDetails(identifiant: self.userSession)
                        
                        self.totalAmount = accountDetails.totalAmount
                        self.recentTransactions = accountDetails.transactions
                        
                } catch let error as APIServiceError {
                        
                        //MARK: Cette logique est là pour gérer l'erreur de token et déclencher une déconnexion globale.
                        if case .tokenInvalidOrExpired = error {
                                /// Si le token est invalide, on se deconnecte
                                print("AccountDetailViewModel: Token expiré détecté, appel de onSessionExpired.")
                                self.onSessionExpired()
                        } else {
                                /// Pour toutes les autres erreurs APIServiceError, on affiche le message.
                                self.errorMessage = error.errorDescription
                        }
                        
                } catch {
                        print("AccountDetailViewModel: Échec - Erreur inattendue: \(error.localizedDescription)")
                        self.errorMessage = "Une erreur inattendue est survenue."
                }
        }
}

//MARK: Changements.
//1. Delete the struct Transaction {description:String,amount:String} because en contraduction with our business model Transaction.
//2. change on Transaction properties names : value/amount and label/description
//3. change in values type for Decimal
//4. change in totalAmount type from String to Decimal.
//5. Annonce d'expiration de session
