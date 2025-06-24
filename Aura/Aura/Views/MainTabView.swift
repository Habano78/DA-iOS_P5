//
//  MainTabView.swift
//  Aura
//
//  Created by Perez William on 18/06/2025.
//

//MARK: Ce fichier est maintenant entièrement dédié à l'interface principale post-connexion.
import SwiftUI

struct MainTabView: View {
        
        @EnvironmentObject var appViewModel: AppViewModel
        
        var body: some View {
                TabView {
                        //MARK: onglet Compte
                        if let accountVM = appViewModel.stockedAccountDetailViewModel {
                                NavigationStack {
                                        AccountDetailView(viewModel: accountVM)
                                }
                                .tabItem {
                                        Label("Compte", systemImage: "person.crop.circle.fill")
                                }
                        } else {
                                ProgressView()
                                        .tabItem {
                                                Label("Compte", systemImage: "person.crop.circle.fill")
                                        }
                        }
                        
                        //MARK: Onglet Transfert
                        if let transferVM = appViewModel.stockedMoneyTransferViewModel {
                                NavigationStack {
                                        MoneyTransferView(viewModel: transferVM)
                                                .navigationTitle("Effectuer un Virement")
                                }
                                .tabItem {
                                        Label("Virement", systemImage: "arrow.right.arrow.left.circle.fill")
                                }
                        } else {
                                ProgressView()
                                        .tabItem {
                                                Label("Virement", systemImage: "arrow.right.arrow.left.circle.fill")
                                        }
                        }
                }
                .accentColor(Color(hex: "#94A684"))
        }
}
