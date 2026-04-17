import Security
import SwiftUI

struct KeychainHelper {
    static func savePassword(_ password: String, for username: String) -> Bool {
        let data = Data(password.utf8)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: username,
            kSecValueData: data
        ] as CFDictionary
        
        SecItemDelete(query) // Delete existing before saving new
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }
    
    static func getPassword(for username: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: username,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let password = String(data: data, encoding: .utf8) {
            return password
        }
        return nil
    }
    
    static func deletePassword(for username: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: username
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}

