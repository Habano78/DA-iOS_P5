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
                // La List est le contenu principal. Le .navigationTitle et le .toolbar
                // s'appliqueront à la NavigationStack qui englobe la vue le .sheet d'AccountDetailView
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
                                Spacer() /// Pousse le montant vers la droite
                                ///Affiche la valeur de la transaction, formatée en devise.
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
                //MARK: Ajout d'une barre d'outils avec un bouton "Fermer"
                .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) { ///bouton à droite
                                Button("Fermer") { ///Texte du bouton
                                        dismiss() ///appelle dismiss pour fermer la feuille.
                                }
                        }
                }
        }
}
