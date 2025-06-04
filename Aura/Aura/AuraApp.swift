//
//  AuraApp.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

// AuraApp.swift
import SwiftUI

@main
struct AuraApp: App {
        @StateObject var viewModel = AppViewModel()
        
        var body: some Scene {
                WindowGroup {
                        Group {
                                if viewModel.isLogged {
                                        TabView {
                                                // MARK: On vérifie si stockedAccountDetailViewModel n'est pas nil
                                                if let accountVM = viewModel.stockedAccountDetailViewModel {
                                                        AccountDetailView(viewModel: accountVM) // On passe l'instance non optionnelle
                                                                .tabItem {
                                                                        Image(systemName: "person.crop.circle")
                                                                        Text("Account")
                                                                }
                                                } else {
                                                        // Ce cas ne devrait pas arriver si isLogged est true et que le login
                                                        // a correctement créé stockedAccountDetailViewModel.
                                                        // Un ProgressView ou un message peut être affiché en attendant.
                                                        ProgressView("Chargement du compte...")
                                                                .tabItem {
                                                                        Image(systemName: "person.crop.circle")
                                                                        Text("Account")
                                                                }
                                                }
                                                
                                                // MARK: On fait la même chose pour MoneyTransferView
                                                if let transferVM = viewModel.stockedMoneyTransferViewModel {
                                                        MoneyTransferView(viewModel: transferVM) // On passe l'instance non optionnelle
                                                                .tabItem {
                                                                        Image(systemName: "arrow.right.arrow.left.circle")
                                                                        Text("Transfer")
                                                                }
                                                } else {
                                                        ProgressView("Chargement du transfert...")
                                                                .tabItem {
                                                                        Image(systemName: "arrow.right.arrow.left.circle")
                                                                        Text("Transfer")
                                                                }
                                                }
                                                // Vous pourriez ajouter d'autres onglets ici si nécessaire
                                        }
                                } else {
                                        AuthenticationView(viewModel: viewModel.authenticationViewModel)
                                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                        removal: .move(edge: .top).combined(with: .opacity)))
                                }
                        }
                        .accentColor(Color(hex: "#94A684")) // Assurez-vous que Color(hex:) est défini
                        // (A) Attention à cette animation, elle pourrait se redéclencher souvent
                        // .animation(.easeInOut(duration: 0.5), value: UUID())
                }
        }
}
