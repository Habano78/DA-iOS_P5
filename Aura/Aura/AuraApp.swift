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
        
        //MARK: Le seul rôle d'AuraApp est de créer la vue racine (ContentView) et de lui fournir le AppViewModel via l'environnement.
        var body: some Scene {
                WindowGroup {
                        ContentView()
                                .environmentObject(viewModel)
                }
        }
}
