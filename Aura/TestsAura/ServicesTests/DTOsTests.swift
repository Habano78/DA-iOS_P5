//
//  ModelTests.swift
//  AuraTests
//
//  Created by Perez William on 05/06/2025.
//

import Testing
@testable import Aura
import Foundation


struct DTOTests {
        
        
        @Test("decodage from JSON to DATA(swift) in AuthResponseDTO")
        func authResponseDTODecodingSucceeds() throws {
                //MARK: ARRANGE
                ///chaine json valide
                let jsonString: String = """
                {
                        "token": "token-test-14273"
                }
                """
                ///convertir le JSON en data compatible SWIFT
                let jsonData = try #require(jsonString.data(using: .utf8))
                let decode = JSONDecoder()
                //MARK:
                let jSONdecodedDTO = try decode.decode(AuthResponseDTO.self, from: jsonData)
                //MARK: ASSERT
                #expect(jSONdecodedDTO.token == "token-test-14273")
        }
        
        
        @Test("encodade: from DATA to JSON in AuthRequestDTO")
        func authRequestDTOEncodingSucceds() throws {
                //MARK: ARRANGE
                let dtoToEncode = AuthRequestDTO(username: "testUser", password: "testPassword")
                let encoder = JSONEncoder()
                let jsonDATAEncoded = try encoder.encode(dtoToEncode)
                //MARK: ACT
                let decodedDictionary = try JSONDecoder().decode([String: String].self, from: jsonDATAEncoded)
                //MARK: ASSERT
                #expect(decodedDictionary.count == 2 )
                #expect(decodedDictionary["username"] == "testUser")
                #expect(decodedDictionary["password"] == "testPassword")
        }
        
        
        
        @Test("vérifier que notre application sait lire un objet JSON qui contient un tableau d'autres objets.")
        func testAccountDetailsDTODecodingSucceeds () throws {
                //MARK: ARRANGE
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
                let jsonDATA = try #require(jsonString.data(using: .utf8))
                let decoder = JSONDecoder()
                //MARK: ACT
                let decodedDTO = try decoder.decode(AccountDetailsDTO.self, from: jsonDATA)
                
                //MARK: ASSERT
                guard decodedDTO.transactions.count == 3 else {
                        Issue.record("Le nombre de transactions attendu était 3, mais nous en avons trouvé \(decodedDTO.transactions.count).")
                        return
                }
                #expect(decodedDTO.transactions[0].label == "Salaire")
                #expect(decodedDTO.transactions[0].value == Decimal(2000.00))
                #expect(decodedDTO.transactions[1].label == "Courses")
                #expect(decodedDTO.transactions[1].value == Decimal(-75.44))
                #expect(decodedDTO.transactions[2].label == "Restaurant")
                #expect(decodedDTO.transactions[2].value == Decimal(-32.50 ))
        }
}
