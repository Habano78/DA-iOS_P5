//
//  AccountDetailView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct AccountDetailView: View {
        
        @ObservedObject var viewModel: AccountDetailViewModel
        
        //MARK: accès à l'AppViewModel pour l'appel de logout()
        @EnvironmentObject var appViewModel: AppViewModel

        @State private var showTransactionsList: Bool = false
        
        var body: some View {
                
                Group {
                        if viewModel.isLoading {
                                ProgressView("Chargement des détails du compte...")
                                        .progressViewStyle(.circular)
                        }
                        else if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 20) {
                                        Text("Erreur")
                                                .font(.title2)
                                                .foregroundColor(.red)
                                        Text(errorMessage)
                                                .foregroundColor(.red)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        
                                        Button("Réessayer") {
                                                Task {
                                                        await viewModel.getAccountDetails()
                                                }
                                        }
                                        .padding()
                                        .buttonStyle(.borderedProminent)
                                }
                                .padding()
                        } else {
                                ScrollView {
                                        
                                        VStack(spacing: 20) {
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
                                                
                                                //MARK: afichage des recents transactions
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
                                                
                                                //MARK: la valeur de showTransactionsList passe à true.
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
                                }
                                .navigationTitle("My Account")
                                .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                                Button("Déconnexion", role: .destructive) {
                                                        //MARK: appelle de la méthode logout de AppViewModel
                                                        appViewModel.logout()
                                                }
                                        }
                                }
                        }
                }
                .onAppear {
                        Task {
                
                                await viewModel.getAccountDetails()
                        }
                }
                //MARK: AJOUT DU MODIFICATEUR .sheet ICI, attaché au Group
                .sheet(isPresented: $showTransactionsList) {
                      
                        let transactionListVM = TransactionListViewModel(transactions: viewModel.recentTransactions)
        
                        NavigationStack {
                                TransactionListView(viewModel: transactionListVM)
                        }
                }
        }
}
