//
//  AccountDetailView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct AccountDetailView: View {
        
        @ObservedObject var viewModel: AccountDetailViewModel
        
        ///cette  accès à l'AppViewModel permet d'appeler logout()
        @EnvironmentObject var appViewModel: AppViewModel
        
        ///@State car SwiftUI reconstruit automatiquement les parties de la vue qui dépendent de cette propriété
        @State private var showTransactionsList: Bool = false
        
        var body: some View {
                //MARK: Group permet d'appliquer .onAppear à toute la logique conditionnelle
                Group {
                        // Affichage conditionnel basé sur isLoading
                        if viewModel.isLoading {
                                ProgressView("Chargement des détails du compte...")
                                        .progressViewStyle(.circular)
                        } // Sinon, s'il y a un message d'erreur...
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
                                        .padding()
                                        .buttonStyle(.borderedProminent)
                                }
                                .padding() /// Ajoute un peu d'espace autour du contenu d'erreur
                        } else {
                                ScrollView { /// On enveloppe le contenu dans une ScrollView
                                        VStack(spacing: 20) {
                                                /// Contenu avec le solde et la liste des transactions)
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
                                                                HStack {/// HStack pour une seule transaction)
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
                                                Button(action: { self.showTransactionsList = true }) {
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
                                        }
                                } /// Fin de la ScrollView
                                //MARK: Ces modificateurs, attachés à la ScrollView la NavigationStack parente (dans MainTabView) les utilisera pour afficher la barre.
                                .navigationTitle("Mon Compte")
                                .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                                Button("Déconnexion", role: .destructive) {
                                                        // Action : appelle la méthode logout de AppViewModel
                                                        appViewModel.logout()
                                                }
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
        }
}
