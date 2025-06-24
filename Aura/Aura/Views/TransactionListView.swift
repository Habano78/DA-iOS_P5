//
//  TransactionListView.swift
//  Aura
//
//  Created by Perez William on 04/06/2025.
//
// TransactionListView.swift

import SwiftUI

struct TransactionListView: View {
        
        @ObservedObject var viewModel: TransactionListViewModel
        @Environment(\.dismiss) var dismiss ///accès à la fermeture fournie par l'environnement SwiftUI
        
        var body: some View {
                
                List(viewModel.transactions) { transaction in
                        
                        HStack {
                                VStack(alignment: .leading) {
                                        HStack {
                                                
                                                Image(systemName: transaction.value >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                                                        .foregroundColor(transaction.value >= 0 ? .green : .red)
                                                Text(transaction.label)
                                                        .font(.headline)
                                        }
                                }
                                Spacer()
                                Text(transaction.value, format: .currency(code: "EUR"))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(transaction.value >= 0 ? .green : .red)
                        }
                        .padding(.vertical, 4)
                }
                .navigationTitle("Toutes les Transactions")
                .overlay {
                        if viewModel.transactions.isEmpty {
                                Text("Aucune transaction à afficher.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                        }
                }
                //MARK: Ajout d'une barre d'outils avec un bouton "Fermer"
                .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Fermer") {
                                        dismiss()
                                }
                        }
                }
        }
}
