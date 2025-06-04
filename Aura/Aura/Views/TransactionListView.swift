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
        
        var body: some View {
                // viewModel.transactions est un Array de nos modèles métier 'Transaction'.
                // grâce à sa propriété 'id: UUID' List peut itérer dessus directement.
                List(viewModel.transactions) { transaction in
                        //Chaque transaction est affichée dans une HStack pour un alignement horizontal.
                        HStack {
                                // Affiche l'icône conditionnelle et le label de la transaction
                                VStack(alignment: .leading) {
                                        HStack {
                                                /// Icône indiquant si la transaction est un crédit ou un débit.
                                                Image(systemName: transaction.value >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                                                        .foregroundColor(transaction.value >= 0 ? .green : .red)
                                                
                                                Text(transaction.label) /// Affiche le label de la transaction.
                                                        .font(.headline)
                                        }
                                }
                                
                                Spacer() /// Pousse le montant vers la droite.
                                
                                //Affiche la valeur de la transaction, formatée en devise.
                                Text(transaction.value, format: .currency(code: "EUR"))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(transaction.value >= 0 ? .green : .red)
                        }
                        .padding(.vertical, 4) ///espacement vertical pour chaque rangée.
                }
                //On Définit ici le titre pour la vue, visible si cette vue est dans une NavigationStack.
                .navigationTitle("Toutes les Transactions")
                //Si la liste est vide, on pourrait afficher un message.
                .overlay {
                        if viewModel.transactions.isEmpty {
                                Text("Aucune transaction à afficher.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                        }
                }
        }
}

// MARK: - Preview

// Pour le Preview, nous créons des données factices.
private struct MockTransactionList {
        static var sampleTransactions: [Transaction] = [
                Transaction(value: Decimal(-850.00), label: "Loyer Mensuel"),
                Transaction(value: Decimal(-250.50), label: "Remboursement Prêt"),
                Transaction(value: Decimal(-78.23), label: "Courses de la semaine"),
                Transaction(value: Decimal(2350.00), label: "Salaire Entreprise X"),
                Transaction(value: Decimal(45.00), label: "Vente Objet Y")
        ]
        
        static var emptyTransactions: [Transaction] = []
}

#Preview("Liste avec Transactions") {
        // Crée une instance de TransactionListViewModel avec des données d'exemple.
        let viewModel = TransactionListViewModel(
                transactions: MockTransactionList.sampleTransactions
        )
        
        // Enveloppe la vue dans une NavigationStack pour voir le navigationTitle.
        return NavigationStack {
                TransactionListView(viewModel: viewModel)
        }
}

#Preview("Liste Vide") {
        let viewModel = TransactionListViewModel(
                transactions: MockTransactionList.emptyTransactions
        )
        
        return NavigationStack {
                TransactionListView(viewModel: viewModel)
        }
}
