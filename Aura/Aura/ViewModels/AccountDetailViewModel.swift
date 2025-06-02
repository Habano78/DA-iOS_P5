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
}

//MARK: Changes.
//1. Delete the struct Transaction {description:String,amount:String} because en contraduction with our business model Transaction.
//2. change on Transaction properties names : value/amount and label/description
//3. change in values type for Decimal
//4. change in totalAmount type from String to Decimal.
