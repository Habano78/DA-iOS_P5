//
//  KeyChainInterface.swift
//  Aura
//
//  Created by Perez William on 05/06/2025.
//

import Foundation
import Security

protocol KeychainInterface {
        func save(label: String, attributes: [String: Any]) throws
        func retrieve(label: String, queryAttributes: [String: Any]) throws -> [String: Any]
        func update(label: String, queryAttributes: [String: Any], attributes: [String: Any]) throws
        func delete(label: String) throws
}

class KeychainService: KeychainInterface {
        enum KeychainError: Error {
                case itemNotFound
                case duplicateItem
                case unexpectedStatus(OSStatus)
                case unexpectedData
        }
        
        func save(label: String, attributes: [String: Any]) throws {
                var query: [String: Any] = [
                        kSecAttrLabel as String: label,
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
                ]
                
                for (key, value) in attributes {
                        query[key] = value
                }
                
                let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
                
                if status == errSecDuplicateItem {
                      
                        let statusUpdate = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
                        
                        guard statusUpdate == errSecSuccess else {
                                throw KeychainError.unexpectedStatus(statusUpdate)
                        }
                } else {
                        guard status == errSecSuccess else {
                                throw KeychainError.unexpectedStatus(status)
                        }
                }
        }
        
        func retrieve(label: String, queryAttributes: [String: Any] = [:]) throws -> [String: Any] {
                var query: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrLabel as String: label,
                        kSecMatchLimit as String: kSecMatchLimitOne,
                        kSecReturnAttributes as String: true,
                        kSecReturnData as String: true
                ]
                
                for (key, value) in queryAttributes {
                        query[key] = value
                }
                
                var item: CFTypeRef?
                let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)
                
                guard status != errSecItemNotFound else {
                        throw KeychainError.itemNotFound
                }
                
                guard status == errSecSuccess else {
                        throw KeychainError.unexpectedStatus(status)
                }
                
                guard let item = item as? [String: Any] else {
                        throw KeychainError.unexpectedData
                }
                
                return item
        }
        
        func update(label: String, queryAttributes: [String: Any], attributes: [String: Any]) throws {
                var query: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrLabel as String: label
                ]
                
                for (key, value) in queryAttributes {
                        query[key] = value
                }
                
                let status: OSStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
                
                guard status != errSecItemNotFound else {
                        throw KeychainError.itemNotFound
                }
                
                guard status == errSecSuccess else {
                        throw KeychainError.unexpectedStatus(status)
                }
        }
        
        func delete(label: String) throws {
                let query: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrLabel as String: label
                ]
                
                let status: OSStatus = SecItemDelete(query as CFDictionary)
                
                guard status == errSecSuccess || status == errSecItemNotFound else {
                        throw KeychainError.unexpectedStatus(status)
                }
        }
}
