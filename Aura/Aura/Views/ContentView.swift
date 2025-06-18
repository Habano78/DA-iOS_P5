//
//  ContentView.swift
//  Aura
//
//  Created by Perez William on 18/06/2025.
//

import SwiftUI

//MARK: La logique d'aiguillage qui avant était dans AuraApp est maintenant ici. Cette vue est maintenant entièrement dédiée à la décision "quel écran afficher : login ou l'application principale ?".
struct ContentView: View {
        ///Récupère l'AppViewModel partagé depuis l'environnement
        @EnvironmentObject var appViewModel: AppViewModel
        
        var body: some View {
                if appViewModel.isLogged {
                        // Si connecté, on affiche la vue principale avec les onglets
                        MainTabView()
                } else {
                        // Sinon, on affiche l'écran de connexion
                        AuthenticationView(viewModel: appViewModel.authenticationViewModel)
                }
        }
}
