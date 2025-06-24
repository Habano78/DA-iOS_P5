//
//  TransactionListViewModel.swift
//  Aura
//
//  Created by Perez William on 04/06/2025.
//

import Foundation

//MARK: actions de TransactionListViewModel: détenir et fournir une liste de transactions.
class TransactionListViewModel: ObservableObject {
        
        @Published var transactions: [Transaction] = []
        
        init(transactions: [Transaction]) {
                self.transactions = transactions
        }
}

//MARK: Nouvelle view. Sa principale responsabilité est de recevoir une liste de transactions (nos modèles métier Transaction) et de la rendre disponible pour TransactionListView.
//Selon le Kanban, ce viewmodel ne doit pas faire une nouveau appel API.
//Il recevra donc les transactions directement de AccountDetailViewModel

