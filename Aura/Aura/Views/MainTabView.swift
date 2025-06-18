//
//  MainTabView.swift
//  Aura
//
//  Created by Perez William on 18/06/2025.
//

//MARK: Ce fichier est maintenant entièrement dédié à l'interface principale post-connexion.
import SwiftUI

struct MainTabView: View {
        // Récupère l'AppViewModel partagé depuis l'environnement
        @EnvironmentObject var appViewModel: AppViewModel
        
        var body: some View {
                TabView {
                        // Onglet Compte
                        if let accountVM = appViewModel.stockedAccountDetailViewModel {
                                NavigationStack { /// Important pour le titre et le bouton logout
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
                        
                        // Onglet Transfert
                        if let transferVM = appViewModel.stockedMoneyTransferViewModel {
                                NavigationStack { /// Important pour donner un titre à la vue
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
