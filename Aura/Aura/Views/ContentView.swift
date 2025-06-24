//
//  ContentView.swift
//  Aura
//
//  Created by Perez William on 18/06/2025.
//

import SwiftUI


struct ContentView: View {
        
        @EnvironmentObject var appViewModel: AppViewModel
        
        var body: some View {
                if appViewModel.isLogged {
                       
                        MainTabView()
                } else {
                        
                        AuthenticationView(viewModel: appViewModel.authenticationViewModel)
                }
        }
}

//MARK: La logique d'aiguillage qui avant était dans AuraApp est maintenant ici. Cette vue est maintenant entièrement dédiée à la décision "quel écran afficher : login ou l'application principale ?".
