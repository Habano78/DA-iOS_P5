//
//  TransactionListVMTest.swift
//  AuraTests
//
//  Created by Perez William on 17/06/2025.
//

import Testing
@testable import Aura
import Foundation


//MARK: TESTs
@Suite(.serialized)
@MainActor
struct TransactionListVMTest {
        
        @Test func test_TransactionListVMTest() async throws {
                //ARRANGE
                let mockTransactions = [
                        Transaction(value: 100, label: "Transaction_1"),
                        Transaction(value: 200, label: "Transaction_2")
                ]
                //ACT
                let viewModel = TransactionListViewModel(transactions: mockTransactions)
                //ASSERT
                #expect(viewModel.transactions.count == 2)
                #expect(viewModel.transactions[0].value == 100)
                #expect(viewModel.transactions[1].value == 200)
                #expect(viewModel.transactions[0].label == "Transaction_1")
                #expect(viewModel.transactions[1].label == "Transaction_2")
        }
        
        @Test func test_TransactionListVMTest_() async throws {
                //ARRANGE
                let mockTransactions: [Transaction ] = []
                //ACT
                let viewModel = TransactionListViewModel(transactions: mockTransactions)
                //ASSERT
                #expect(viewModel.transactions.count == 0)
        }
}
