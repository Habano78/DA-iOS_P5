//
//  MoneyTransferViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

@MainActor
class MoneyTransferViewModel: ObservableObject {
        @Published var recipient: String = ""
        @Published var transferMessage: String = ""
        ///Modifi: Cette propriété était typée "String", car le TextField de SwiftUI est conçu pour être lié (bindé) directement à une propriété de type String. Il est donc indispensable d'avoir une étape où : On valide que la String saisie par l'utilisateur représente bien un nombre valide. On convertit cette String valide en un type Decimal.
        @Published var amount: String = ""
        
        //MARK: Propriétés d'état pour le chargement et messages (erreurs et succes)
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        @Published var successMessage: String?
        
        //MARK: Nouvelles propriétés pour injecter les dépendances
        private let transferService: TransferServiceProtocol
        private let userSession: UserSession
        
        init (transferService: TransferServiceProtocol, userSession: UserSession) {
                self.transferService = transferService
                self.userSession = userSession
        }
        
        //MARK: Constructuion de la fonction
        func sendMoney()async {
                isLoading = true
                defer {isLoading = false}
                errorMessage = nil
                successMessage = nil
                
                //MARK: verification du Destinataire et Amount (conversion de String en Decimal et > 0)
                guard !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please enter a recipient"
                        return
                }
                //MARK: verification du montant
                guard !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        errorMessage = "Please enter an amount."
                        return
                }
                //MARK: convertion de amout String en Decimal.Remplacer la virgule par un point.
                guard let decimalAmount = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")) else {
                        errorMessage = "Invalid amount format."
                        return
                }
                
                //MARK: vérification du montant décimal >0
                guard decimalAmount > 0 else {
                        errorMessage = "Le montant du transfert doit être supérieur à zéro."
                        return
                }
                //MARK: Création de l'objet dataToTransfert. A partir d'ici les données sont prêts pour l'appel au service.
                let  dataToTransfert = TransferRequestData(recipient: self.recipient, amount: decimalAmount)
                
                //MARK: Appel au Service et gestion des résultats
                do {
                        
                        try await self.transferService.sendMoney(transferData: dataToTransfert, identifiant: self.userSession)
                        print("MoneyTransferViewModel: Transfert exécuté avec succès via le service.")
                        self.successMessage = "Transfert de \(decimalAmount) à \(dataToTransfert.recipient) effectué avec succès !"
                        //MARK: réinitialiser les champs après un succès
                        self.recipient = ""
                        self.amount = ""
                        
                        //MARK: gestion des erreurs
                } catch let error as APIServiceError {
                        self.errorMessage = error.errorDescription
                } catch {
                        self.errorMessage = "Échec du transfert : une erreur est survenue lors du transfert."
                }
        }
}

