//
//  AuthenticationView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct AuthenticationView: View {
        
        let gradientStart = Color(hex: "#94A684").opacity(0.7)
        let gradientEnd = Color(hex: "#94A684").opacity(0.0) // Fades to transparent
        
        @ObservedObject var viewModel: AuthenticationViewModel
        
        var body: some View {
                
                ZStack {
                        // Background gradient
                        LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .top, endPoint: .bottomLeading)
                                .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                                Image(systemName: "person.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                
                                Text("Welcome !")
                                        .font(.largeTitle)
                                        .fontWeight(.semibold)
                                
                                TextField("Adresse email", text: $viewModel.username)
                                        .padding()
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .disableAutocorrection(true)
                                
                                SecureField("Mot de passe", text: $viewModel.password)
                                        .padding()
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                                
                                
                                //MARK: Ajout pour afficher qu'AuthViewModel est en train de charger
                                if viewModel.isLoading { ///l'indicateur de chargement apparaît ou disparaît en fonction de viewModel.isLoading.
                                        ProgressView()
                                                .padding(.bottom, 10) /// Un peu d'espace avant le bouton
                                }
                                //MARK: Modification : Task pour prendre en compte l'asynchronicité de login() dans AuthViewModel
                                Button(action: {
                                        Task {
                                                await viewModel.login() ///On appelle la méthode async login() du viewModel avec 'await
                                        }
                                }) {
                                        Text("Se connecter")
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.black)
                                                .cornerRadius(8)
                                }
                                .disabled(viewModel.isLoading) ///Le bouton est désactivé si isLoading est true
                                
                                //MARK: AJOUT POUR LE MESSAGE D'ERREUR
                                /// D'abord on vérifie si viewModel.errorMessage contient une valeur (si ce n'est pas nil)
                                if let errorMessage = viewModel.errorMessage {
                                        ///S'il y a ereur, on affiche le message d'erreur dans un Text
                                        Text(errorMessage)
                                                .foregroundColor(.red) // (C) En rouge pour attirer l'attention
                                                .padding(.top, 5)     // Un peu d'espace au-dessus
                                                .multilineTextAlignment(.center) // Au cas où le message est long
                                                .fixedSize(horizontal: false, vertical: true) // Permet au texte de prendre plusieurs lignes
                                }
                        }
                        .padding(.horizontal, 40)
                }
                .onTapGesture {
                        self.endEditing(true)  // This will dismiss the keyboard when tapping outside
                }
        }
        
}




