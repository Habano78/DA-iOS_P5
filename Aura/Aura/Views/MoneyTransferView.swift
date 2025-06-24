//
//  MoneyTransferView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct MoneyTransferView: View {
        
        //MARK: modifié car cette vue s'attend à recevoir une instance déjà créée de MoneyTransferViewModel
        @ObservedObject var viewModel: MoneyTransferViewModel
        
        @State private var animationScale: CGFloat = 1.0
        
        var body: some View {
                VStack(spacing: 20) {
                        // Adding a fun header image
                        Image(systemName: "arrow.right.arrow.left.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color(hex: "#94A684"))
                                .padding()
                                .scaleEffect(animationScale)
                                .onAppear {
                                        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                                animationScale = 1.2
                                        }
                                }
                        
                        Text("Send Money!")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                        
                        VStack(alignment: .leading) {
                                Text("Recipient (Email or Phone)")
                                        .font(.headline)
                                TextField("Enter recipient's info", text: $viewModel.recipient)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .keyboardType(.emailAddress)
                                        .disabled(viewModel.isLoading) 
                        }
                        
                        VStack(alignment: .leading) {
                                Text("Amount (€)")
                                        .font(.headline)
                                TextField("0.00", text: $viewModel.amount)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .keyboardType(.decimalPad)
                                        .disabled(viewModel.isLoading)
                                
                        }
                        //MARK: indicateur de chargement (s'affiche si isLoading est true)
                        if viewModel.isLoading {
                                ProgressView("Envoi en cours...")
                                        .padding(.top, 10)
                        }
        
                        Button(action: {
                                Task {
                                        await viewModel.sendMoney()
                                }
                        }, label: {
                                HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Send")
                                }
                                .padding()
                                .background(Color(hex: "#94A684"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        })
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isLoading)
                        
                        //MARK: Affichage du message de succès
                        if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                        .foregroundColor(.green)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                        }
                        
                        //MARK: Affichage du message d'erreur
                        if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                        .foregroundColor(.red)
                                        .padding(.top, 10)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                }
                .padding()
                .onTapGesture {
                        self.endEditing(true)
                }
        }
}
