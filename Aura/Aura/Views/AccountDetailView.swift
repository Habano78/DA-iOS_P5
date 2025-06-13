//
//  AccountDetailView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct AccountDetailView: View {
        
        @ObservedObject var viewModel: AccountDetailViewModel
        ///@State car SwiftUI reconstruit automatiquement les parties de la vue qui dépendent de cette propriété
        @State private var showTransactionsList: Bool = false
        
        var body: some View {
                //MARK: Group permet d'appliquer .onAppear à toute la logique conditionnelle
                Group {
                        // Affichage conditionnel basé sur isLoading
                        if viewModel.isLoading {
                                ProgressView("Chargement des détails du compte...")
                                        .progressViewStyle(.circular)
                        } // NOUVEAU: Sinon, s'il y a un message d'erreur...
                        else if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 20) { ///Conteneur pour l'erreur et le bouton
                                        Text("Erreur") /// Un titre pour la section erreur
                                                .font(.title2)
                                                .foregroundColor(.red)
                                        Text(errorMessage) /// Affiche le message d'erreur venant du ViewModel
                                                .foregroundColor(.red)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        
                                        Button("Réessayer") { //Bouton pour relancer le chargement
                                                Task {
                                                        await viewModel.getAccountDetails()
                                                }
                                        }
                                        .padding(.top)
                                        .buttonStyle(.borderedProminent)
                                }
                                .padding() /// Ajoute un peu d'espace autour du contenu d'erreur
                        } else {
                                ScrollView {
                                        VStack(spacing: 20) {
                                                /// Large Header displaying total amount
                                                VStack(spacing: 10) {
                                                        Text("Your Balance")
                                                                .font(.headline)
                                                        Text(viewModel.totalAmount, format: .currency(code: "EUR"))
                                                                .font(.system(size: 60, weight: .bold))
                                                                .foregroundColor(Color(hex: "#94A684"))
                                                        Image(systemName: "eurosign.circle.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(height: 80)
                                                                .foregroundColor(Color(hex: "#94A684"))
                                                }
                                                .padding(.top)
                                                
                                                // Display recent transactions
                                                VStack(alignment: .leading, spacing: 10) {
                                                        Text("Recent Transactions")
                                                                .font(.headline)
                                                                .padding([.horizontal])
                                                        ForEach(viewModel.recentTransactions) { transaction in
                                                                HStack {
                                                                        Image(systemName:
                                                                                transaction.value >= 0
                                                                              ? "arrow.up.right.circle.fill"
                                                                              : "arrow.down.left.circle.fill"
                                                                        )
                                                                        .foregroundColor(
                                                                                transaction.value >= 0 ? .green : .red
                                                                        )
                                                                        
                                                                        Text(transaction.label)
                                                                        Spacer()
                                                                        Text(transaction.value, format: .currency(code: "EUR"))
                                                                                .fontWeight(.bold)
                                                                                .foregroundColor(
                                                                                        transaction.value >= 0 ? .green : .red
                                                                                )
                                                                }
                                                                .padding()
                                                                .background(Color.gray.opacity(0.1))
                                                                .cornerRadius(8)
                                                                .padding([.horizontal])
                                                        }
                                                }
                                                
                                                // lorsque l'utilisateur appuie sur ce bouton, la valeur de showTransactionsList passe à true.
                                                Button(action: {
                                                        self.showTransactionsList = true
                                                        print("Bouton 'See Transaction Details' cliqué, showTransactionsList est maintenant: \(self.showTransactionsList)")
                                                }) {
                                                        HStack {
                                                                Image(systemName: "list.bullet")
                                                                Text("See Transaction Details")
                                                        }
                                                        .padding()
                                                        .background(Color(hex: "#94A684"))
                                                        .foregroundColor(.white)
                                                        .cornerRadius(8)
                                                }
                                                .padding([.horizontal, .bottom])
                                                
                                                Spacer()
                                        }
                                }
                        }
                }
                
                .onAppear {
                        Task {
                                ///await pour appeler la fonction async
                                await viewModel.getAccountDetails()
                        }
                }
                //MARK: AJOUT DU MODIFICATEUR .sheet ICI, attaché au Group
                .sheet(isPresented: $showTransactionsList) {
                        ///On crée une instance de TransactionListViewModel.
                        ///On lui passe les transactions actuellement détenues par AccountDetailViewModel.
                        let transactionListVM = TransactionListViewModel(transactions: viewModel.recentTransactions)
                        // On crée et retourne TransactionListView avec son ViewModel.
                        NavigationStack {
                                TransactionListView(viewModel: transactionListVM)
                        }
                }
                .onTapGesture {
                        self.endEditing(true)  // This will dismiss the keyboard when tapping outside
                }
        }
}
