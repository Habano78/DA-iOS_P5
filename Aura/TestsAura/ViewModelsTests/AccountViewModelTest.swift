//
//  AccountViewModelTest.swift
//  AuraTests
//
//  Created by Perez William on 14/06/2025.
//

import Testing
@testable import Aura
import Foundation

// MARK: Ce nous permet de contrôler le résultat de l'appel à getAccountDetails().
private class MockAccountService: AccountServiceProtocol {
        
        /// On peut configurer ce mock pour qu'il retourne un succès ou une erreur.
        var getDetailsResult: Result<AccountDetails, APIServiceError>
        
        init(result: Result<AccountDetails, APIServiceError>) {
                self.getDetailsResult = result
        }
        
        func getAccountDetails(identifiant: UserSession) async throws -> AccountDetails {
                // Retourne le résultat prédéfini.
                return try getDetailsResult.get()
        }
}

//MARK: TESTs
@Suite(.serialized)
@MainActor ///@MainActor car ces tests modifient des @Published var
struct AccountDetailViewModelTests {
        
        @Test("getAccountDetails() en cas de succès, met à jour les propriétés du VM")
        func test_getAccountDetails_onSuccess_updatesProperties() async {
                
                // --- 1. ARRANGE (Préparation) ---
                
                // a. Préparer les données de succès que le mock service retournera.
                let mockTransactions = [Transaction(value: 100, label: "Transaction de test")]
                let expectedAccountDetails = AccountDetails(
                        totalAmount: Decimal(1234.56),
                        transactions: mockTransactions
                )
                
                // b. Créer le mock service configuré pour réussir.
                let mockService = MockAccountService(result: .success(expectedAccountDetails))
                
                // c. Créer une session utilisateur factice (nécessaire pour l'init du VM).
                let dummyUserSession = UserSession(token: "test-token")
                
                // d. Créer l'instance du ViewModel à tester (le SUT).
                let viewModel = AccountDetailViewModel(
                        accountService: mockService,
                        userSession: dummyUserSession
                )
                
                // Pré-vérification (optionnel) : s'assurer que l'état initial est correct
                #expect(viewModel.totalAmount == 0.0) // Basé sur l'init de votre VM
                #expect(viewModel.recentTransactions.isEmpty == true)
                
                // --- 2. ACT (Agir) ---
                
                // On appelle la méthode que l'on veut tester.
                await viewModel.getAccountDetails()
                
                // --- 3. ASSERT (Vérifier) ---
                
                // a. Vérifier les états finaux du ViewModel.
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                #expect(viewModel.errorMessage == nil, "errorMessage devrait être nil en cas de succès.")
                
                // b. Vérifier que les propriétés de données ont été mises à jour.
                #expect(viewModel.totalAmount == expectedAccountDetails.totalAmount, "totalAmount n'a pas été mis à jour correctement.")
                #expect(viewModel.recentTransactions.count == 1, "Le nombre de transactions est incorrect.")
                #expect(viewModel.recentTransactions.first?.label == "Transaction de test", "Le label de la transaction est incorrect.")
        }
        
        @Test("getAccountDetails() en cas d'échec, met à jour le message d'erreur")
        func test_getAccountDetails_onFailure_updatesErrorMessage() async {
                
                // ARRANGE
                /// Préparer le résultat d'échec que notre mock service retournera.
                let expectedError = APIServiceError.tokenInvalidOrExpired
                let mockService = MockAccountService(result: .failure(expectedError))
                
                /// Session utilisateur factice.
                let dummyUserSession = UserSession(token: "un-token-qui-va-echouer")
                
                /// instance du ViewModel à tester (le SUT).
                let viewModel = AccountDetailViewModel(
                        accountService: mockService,
                        userSession: dummyUserSession
                )
                
                ///valeurs initiales des données pour vérifier qu'elles ne changent pas en cas d'erreur.
                let initialAmount = viewModel.totalAmount
                let initialTransactions = viewModel.recentTransactions
                
                //ACT
                /// On appelle la méthode que l'on veut tester.
                await viewModel.getAccountDetails()
                
                //ASSERT
                /// Vérification des états finaux du ViewModel.
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                
                /// Vérification que le message d'erreur a été correctement défini.
                #expect(viewModel.errorMessage == expectedError.errorDescription, "Le message d'erreur ne correspond pas à l'erreur attendue.")
                
                ///Vérifier que les données n'ont pas été modifiées.
                #expect(viewModel.totalAmount == initialAmount, "totalAmount ne devrait pas avoir changé en cas d'erreur.")
                #expect(viewModel.recentTransactions == initialTransactions, "recentTransactions ne devrait pas avoir changé en cas d'erreur.")
        }
}
