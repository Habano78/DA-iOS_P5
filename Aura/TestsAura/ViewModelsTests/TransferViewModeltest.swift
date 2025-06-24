//
//  TransferViewModeltest.swift
//  AuraTests
//
//  Created by Perez William on 14/06/2025.
//

import Testing
@testable import Aura
import Foundation


@Suite(.serialized)
@MainActor
struct TransferViewModeltest {
        
    
        @Test("sendMoney_onSuccess_updatesProperties")
        func test_getAccountDetails_onSuccess_updatesStateAndClearsFields() async {
                
                // ARRANGE
                let mockService = MockTransferService(result: .success(())) /// un suscces est Result<Void>
               
                let dummyUserSession = UserSession (token: "dummyToken")
                
                let viewModel = MoneyTransferViewModel(
                        transferService: mockService,
                        userSession: dummyUserSession
                )
                
                let recipient = "ami@example.com"
                let amountString = "50,25" // On simule la saisie avec une virgule
                let expectedAmountDecimal = Decimal(50.25)
                
                viewModel.recipient = recipient
                viewModel.amount = amountString
                
                //MARK: ACT
                await viewModel.sendMoney()
                
                // ASSERT
                #expect(viewModel.isLoading == false, "isLoading devrait être false après l'appel.")
                #expect(viewModel.errorMessage == nil, "errorMessage devrait être nil en cas de succès.")
                #expect(viewModel.successMessage != nil, "Un message de succès était attendu.")
                ///Vérifier que les champs de saisie ont été réinitialisés après le succès.
                #expect(viewModel.recipient.isEmpty, "Le champ 'recipient' aurait dû être vidé.")
                #expect(viewModel.amount.isEmpty, "Le champ 'amount' aurait dû être vidé.")
                ///Vérifier que le service a été appelé correctement (grâce à nos "espions").
                #expect(mockService.sendMoneyCallCount == 1, "La méthode sendMoney du service aurait dû être appelée une seule fois.")
                #expect(mockService.receivedTransferData?.recipient == recipient, "Le destinataire envoyé au service est incorrect.")
                #expect(mockService.receivedTransferData?.amount == expectedAmountDecimal, "Le montant envoyé au service est incorrect.")
                #expect(mockService.receivedUserSession?.token == dummyUserSession.token, "La session utilisateur envoyée au service est incorrecte.")
        }
        
        @Test("L'utilisateur ne saisie pas de destinataire")
        func testSendMoney_onEmptyRecipient_setsErrorMessageAndDoesNotCallService() async {
                // ARRANGE
                let mockTransferService = MockTransferService(result: .success(()))
                let userSession = UserSession (token: "Token")
                let viewModel = MoneyTransferViewModel(transferService: mockTransferService, userSession: userSession)
                viewModel.recipient = "" /// erreur à simuler : saisie vide.
                viewModel.amount = "100"
                
                // ACT
                await viewModel.sendMoney()
                
                // ASSERT
                #expect(viewModel.errorMessage == "Please enter a recipient")
                #expect(mockTransferService.sendMoneyCallCount == 0)
        }
        @Test("Le champ amount est Vide")
        func sendMoney_onEmptyAmount_setsErrorMessageAndDoesNotCallService() async {
                // ARRANGE
                let mockTransferService = MockTransferService(result: .success(()))
                let userSession = UserSession (token: "Token")
                let viewModel = MoneyTransferViewModel(
                        transferService: mockTransferService,
                        userSession: userSession)
              
                viewModel.recipient = "mon@email.com"
                viewModel.amount = ""/// erreur à simuler : saisie vide.
                
                // ACT
                await viewModel.sendMoney()
                
                // ASSERT
                #expect(viewModel.errorMessage == "Please enter an amount.")
                #expect(mockTransferService.sendMoneyCallCount == 0)
        }
        @Test("Le champ amount n'est pas un nombre")
        func sendMoney_onWrongNumberAmount_setsErrorMessageAndDoesNotCallService() async {
                // ARRANGE
                let mockTransferService = MockTransferService(result: .success(()))
                let userSession = UserSession (token: "Token")
                let viewModel = MoneyTransferViewModel(
                        transferService: mockTransferService,
                        userSession: userSession)
                /// On simule ici la saisie utilisateur avec l'erreur
                viewModel.recipient = "mon@email.com"
                viewModel.amount = "UUUu"/// erreur à simuler : la saisie n'est pas un nombre.
                
                // ACT
                await viewModel.sendMoney()
                
                // ASSERT
                #expect(viewModel.errorMessage == "Invalid amount format.")
                #expect(mockTransferService.sendMoneyCallCount == 0)
        }
        @Test("Le montant du transfert doit être supérieur à zéro.")
        func sendMoney_onNegatifOrZeroAmount_setsErrorMessageAndDoesNotCallService() async {
                // ARANGE
                let mockTransferService = MockTransferService(result: .success(()))
                let userSession = UserSession (token: "Token")
                let viewModel = MoneyTransferViewModel(
                        transferService: mockTransferService,
                        userSession: userSession)
        
                viewModel.recipient = "mon@email.com"
                viewModel.amount = "-30"/// erreur à simuler : la saisie n'est pas un nombre.
                // ACT
                await viewModel.sendMoney()
                // ASSERT
                #expect(viewModel.errorMessage == "Le montant du transfert doit être supérieur à zéro.")
                #expect(mockTransferService.sendMoneyCallCount == 0)
        }
        
        @Test("sendMoney() en cas d'échec du service, met à jour le message d'erreur")
        func testSendMoney_onServiceFailure_updatesErrorMessage() async {
                // ARANGE
                let error = APIServiceError.unexpectedStatusCode(500)
                let mockTransferService = MockTransferService(result: .failure(error))
                let userSession = UserSession (token: "Token")
                let viewModel = MoneyTransferViewModel(
                        transferService: mockTransferService,
                        userSession: userSession)
                
                viewModel.recipient = "mon@truc.com"
                viewModel.amount = "100"
                
                // ACT
                await viewModel.sendMoney()
                
                // ASSERt
                #expect(mockTransferService.sendMoneyCallCount == 1) /// Le service a bien été appelé
                #expect(viewModel.errorMessage == error.errorDescription) /// Le bon message d'erreur est affiché
                #expect(viewModel.successMessage == nil) /// Pas de message de succès
                #expect(viewModel.isLoading == false)
                #expect(viewModel.recipient.isEmpty == false) /// Les champs ne sont pas vidés en cas d'échec
                #expect(viewModel.amount.isEmpty == false)
        }
        
        @Test("sendMoney() en cas d'erreur inattendue, affiche un message générique")
        func testSendMoney_onUnexpectedError_setsGenericErrorMessage() async {
                // ARRANGE
                struct CustomError: Error {}
                let unexpectedError = CustomError()
                let mockService = MockTransferService(result: .failure(unexpectedError))
                let viewModel = MoneyTransferViewModel(
                        transferService: mockService,
                        userSession: UserSession(token: "test")
                )
                viewModel.recipient = "ami@valide.com"
                viewModel.amount = "100"
                
                // ACT
                await viewModel.sendMoney()
                
                // ASSERT
                #expect(viewModel.errorMessage == "Échec du transfert : une erreur est survenue lors du transfert.")
                #expect(viewModel.successMessage == nil)
                #expect(mockService.sendMoneyCallCount == 1)
        }
}
