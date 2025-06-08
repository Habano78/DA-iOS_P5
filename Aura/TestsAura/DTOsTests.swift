//
//  ModelTests.swift
//  AuraTests
//
//  Created by Perez William on 05/06/2025.
//
//MARK: Avec "testing" plus besoin que le classe de test hérite de XCTestCase. On peut utiliser une struct pour regrouper les tests, ou même des fonctions de test globales. Les fonctions de test sont marquées avec l'attribut @Test. Les assertions se font avec #expect(...)

import Testing
@testable import Aura // Donne accès au fichiers
import Foundation // Pour JSONDecoder, Data, etc.


struct DTOTests {
        
        //MARK: on teste ici le decodage: from JSON to DATA(swift) in AuthResponseDTO
        @Test
        func authResponseDTODecodingSucceeds() throws {
                ///1. définir une chaine json valide
                let jsonString: String = """
                {
                        "token": "token-test-14273"
                }
                """
                /// 2. convertir la chaine en data compatible SWIFT
                let jsonData = try #require(jsonString.data(using: .utf8))///#require est là pour faire échouer le test si la conversion retourne nil
                /// 3. créer un décoder
                let decode = JSONDecoder()
                ///tenter de decoder
                let jSONdecodedDTO = try decode.decode(AuthResponseDTO.self, from: jsonData)
                // VÉRIFICATION
                #expect(jSONdecodedDTO.token == "token-test-14273")
                
        }
        
        //MARK: on teste ici l'encodade: from DATA to JSON in AuthRequestDTO
        @Test
        func authRequestDTOEncodingSucceds() throws {
                ///instance de AuthRequestDTO pour créer l'objet a Encoder
                let dtoToEncode = AuthRequestDTO(username: "testUser", password: "testPassword")
                /// instance de JSONEncoder + encodage pour recuperer notre type DATA
                let encoder = JSONEncoder()
                let jsonDATAEncoded = try encoder.encode(dtoToEncode)
                ///DÉCODE les Data JSON en un dictionnaire [String: String] pour la vérification.
                let decodedDictionary = try JSONDecoder().decode([String: String].self, from: jsonDATAEncoded)
                
                //On VÉRIFIE les valeurs du dictionnaire avec #expect.
                #expect(jsonDATAEncoded.count == 2 )
                #expect(decodedDictionary["username"] == "testUser")
                #expect(decodedDictionary["password"] == "testPassword")
        }
        
        
        //MARK: Ce test va vérifier que notre application sait lire un objet JSON qui contient un tableau d'autres objets.
        @Test
        func testAccountDetailsDTODecodingSucceeds () throws {
                ///1. définition de l'exemple
                // Dans votre méthode de test
                let jsonString = """
        {
            "currentBalance": 12.56,
            "transactions": [
                {
                    "label": "Salaire",
                    "value": 2000.00
                },
                {
                    "label": "Courses",
                    "value": -75.44
                },
                {
                    "label": "Restaurant",
                    "value": -32.50
                }
            ]
        }
        """
                ///2. conversion de JSON a DATA
                let jsonDATA = try #require(jsonString.data(using: .utf8))
                /// Construction del decodeur
                let decoder = JSONDecoder()
                ///
                let decodedDTO = try decoder.decode(AccountDetailsDTO.self, from: jsonDATA)
                
                // VÉRIFICATIONs
                /// tout d'abord vérification que le tableau contient exactement 3 transactions.
                guard decodedDTO.transactions.count == 3 else {
                        /// Si la condition est fausse, ce bloc est exécuté.
                        Issue.record("Le nombre de transactions attendu était 3, mais nous en avons trouvé \(decodedDTO.transactions.count).")
                        return // La fonction de test s'arrête ici.
                }
                /// Toute cette partie du test ne s'exécute QUE si le guard est passé.
                #expect(decodedDTO.transactions[0].label == "Salaire")
                #expect(decodedDTO.transactions[0].value == Decimal(2000.00))
                #expect(decodedDTO.transactions[1].label == "Courses")
                #expect(decodedDTO.transactions[1].value == Decimal(-75.44))
                #expect(decodedDTO.transactions[2].label == "Restaurant")
                #expect(decodedDTO.transactions[2].value == Decimal(-32.50 ))
        }
}
