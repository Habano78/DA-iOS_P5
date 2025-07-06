//
//  TransactionListView.swift
//  Aura
//
//  Created by Perez William on 04/06/2025.
//

import SwiftUI

struct TransactionListView: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
       
        List {
           
            ForEach(viewModel.transactions) { transaction in
                
                VStack(alignment: .leading, spacing: 0) {
                    /// affichage d'une seule transaction.
                    HStack {
                        Image(systemName: transaction.value >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                            .foregroundColor(transaction.value >= 0 ? .green : .red)
                        
                        Text(transaction.label)
                            .font(.headline)

                        Spacer()

                        Text(transaction.value, format: .currency(code: "EUR"))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(transaction.value >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 8)
                  
                    Divider()
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Toutes les Transactions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
        .overlay {
            if viewModel.transactions.isEmpty {
                Text("Aucune transaction à afficher.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}


// MARK: Preview

private struct MockTransactionListForPreview {
        static let sampleTransactions: [Transaction] = [
        Transaction(value: Decimal(-850.00), label: "Loyer Mensuel"),
        Transaction(value: Decimal(-250.50), label: "Remboursement Prêt"),
        Transaction(value: Decimal(-78.23), label: "Courses de la semaine"),
        Transaction(value: Decimal(2350.00), label: "Salaire Entreprise X"),
        Transaction(value: Decimal(45.00), label: "Vente Objet Y")
    ]
}

#Preview("Liste avec Transactions") {
    let viewModel = TransactionListViewModel(
        transactions: MockTransactionListForPreview.sampleTransactions
    )
    /// vue enveloppée dans une NavigationStack pour voir le titre et le bouton toolbar.
    return NavigationStack {
        TransactionListView(viewModel: viewModel)
    }
}
