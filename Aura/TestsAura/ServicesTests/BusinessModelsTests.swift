//
//  BusinessModelsTests.swift
//  AuraTests
//
//  Created by Perez William on 07/06/2025.
//

import Testing
import Foundation
@testable import Aura

struct BusinessModelsTests {
        
        @Test
        func testUserSessionInitialization() throws {
               // ARRANGE
                let token:String = "un-token-pour-le-test"
                // ACT
                let userSession = UserSession(token: token)
                // ASSERT
                #expect(userSession.token == token)
        }
        //MARK: Mapping de TransactionDTO vers le modèle métier Transaction
        @Test
        func testTransactionMappingFromDTO() throws {
                ///données de tests : instance de TransactionDTO 
                let transactionDTO:TransactionDTO = TransactionDTO(
                        value: 100.0,
                        label: "Aspirateur")
                let transactionMetier:Transaction = Transaction(from: transactionDTO)
                // Vérification
                ///On vérifie que la propriété 'label' a été correctement copiée.
                #expect(transactionMetier.label == transactionDTO.label)
                ///On vérifie que la propriété 'value' a été correctement copiée.
                #expect(transactionMetier.value == transactionDTO.value)
                
        }
        
        @Test
        func
        testAccountDetailsMappingFromDTO()  throws {
                let dtoTransactions = [
                        TransactionDTO(value: 50.0, label: "Café"),
                        TransactionDTO(value:15.0, label: "Lait")
                ]
                let dtoAccountDetails:AccountDetailsDTO = AccountDetailsDTO(currentBalance: 100.0, transactions: dtoTransactions)
                let accountDetailsMetier:AccountDetails = AccountDetails(from: dtoAccountDetails)
                #expect(dtoTransactions.count == 2)
                #expect(dtoTransactions.count == accountDetailsMetier.transactions.count)
                #expect(accountDetailsMetier.totalAmount == dtoAccountDetails.currentBalance)
                #expect(accountDetailsMetier.transactions[0].value == dtoTransactions[0].value)
                #expect(accountDetailsMetier.transactions[0].label == dtoTransactions[0].label)
                #expect(accountDetailsMetier.transactions[1].value == dtoTransactions[1].value)
                #expect(accountDetailsMetier.transactions[1].label == dtoTransactions[1].label)
        }
}
