//
//  AccountViewModelTest.swift
//  AuraTests
//
//  Created by Perez William on 14/06/2025.
//

import Testing
@testable import Aura
import Foundation


@Suite(.serialized)
@MainActor
struct AccountDetailViewModelTests {
        
        @Test("getAccountDetails() en cas de succès, met à jour les propriétés")
        func test_getAccountDetails_onSuccess_updatesProperties() async {
                // ARRANGE
                let mockData = AccountDetails(totalAmount: 1234.56, transactions: [Transaction(value: 100, label: "Test")])
                let mockService = MockAccountService(result: .success(mockData))
                let viewModel = AccountDetailViewModel(
                        accountService: mockService,
                        userSession: UserSession(token: "test"),
                        onSessionExpired: { Issue.record("onSessionExpired ne devrait pas être appelé.") }
                )
                
                // ACT
                await viewModel.getAccountDetails()
                
                // ASSERT
                #expect(viewModel.isLoading == false)
                #expect(viewModel.errorMessage == nil)
                #expect(viewModel.totalAmount == mockData.totalAmount)
                #expect(mockService.getDetailsCallCount == 1)
        }
        
        
        @Test("getAccountDetails() en cas d'erreur serveur, met à jour errorMessage")
        func test_getAccountDetails_onServerError_updatesErrorMessage() async {
                // ARRANGE
                let expectedError = APIServiceError.unexpectedStatusCode(500)
                let mockService = MockAccountService(result: .failure(expectedError))
                
                let viewModel = AccountDetailViewModel(
                        accountService: mockService,
                        userSession: UserSession(token: "test"),
                        onSessionExpired: { Issue.record("onSessionExpired ne devrait pas être appelé pour cette erreur.") }
                )
                
                // ACT
                await viewModel.getAccountDetails()
                
                // ASSERT
                #expect(viewModel.errorMessage == expectedError.errorDescription, "Le message d'erreur est incorrect.")
                #expect(viewModel.isLoading == false)
                #expect(mockService.getDetailsCallCount == 1)
        }
        
        @Test("getAccountDetails() avec un token invalide, appelle le callback onSessionExpired")
        func test_getAccountDetails_onInvalidToken_callsSessionExpiredCallback() async {
                // ARRANGE
                let mockService = MockAccountService(result: .failure(APIServiceError.tokenInvalidOrExpired))
                ///  "espions" pour vérifier que notre callback est bien appelé.
                var sessionExpiredCallbackWasCalled = false
                let sessionExpiredCallback = {
                        sessionExpiredCallbackWasCalled = true
                }
                
                let viewModel = AccountDetailViewModel(
                        accountService: mockService,
                        userSession: UserSession(token: "invalid-token"),
                        onSessionExpired: sessionExpiredCallback
                )
                
                // ACT
                await viewModel.getAccountDetails()
                
                // ASSERT
                #expect(sessionExpiredCallbackWasCalled == true, "Le callback onSessionExpired aurait dû être appelé.")
                #expect(viewModel.errorMessage == nil, "errorMessage devrait être nil lorsque la session expire.")
                #expect(viewModel.isLoading == false)
                #expect(mockService.getDetailsCallCount == 1)
        }
        @Test("AccountDetailViewModel: Échec - Erreur inattendue")
        func test_AccountDetailViewModel_() async {
                
                // ARRANGE
                struct MonErreurBidon: Error {}
                let unexpectedError = MonErreurBidon()
                ///injection de l'erreur au service
                let mockService = MockAccountService(result: .failure(unexpectedError))
                /// userSession factice
                let userSession = UserSession(token:"token")
                ///instance de VMAccount
                let viewModel = AccountDetailViewModel(
                        accountService: mockService,
                        userSession: userSession,
                        onSessionExpired: { Issue.record("onSessionExpired ne devrait pas être appelé pour cette erreur.") }
                )
                
                // ACT
                await viewModel.getAccountDetails()
                
                // ASSERT
                #expect(viewModel.errorMessage ==  "Une erreur inattendue est survenue.")
                #expect(viewModel.isLoading == false)
                #expect(mockService.getDetailsCallCount == 1)
        }
        
}
