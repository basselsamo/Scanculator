//
//  DataService.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import Foundation

class DataService {
    static let shared = DataService()
    
    private let productKey = "products"
    private let sessionKey = "sessions"
    
    private init() {}

    func saveProducts(_ products: [Product]) {
        if let encoded = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(encoded, forKey: productKey)
        }
    }
    
    func loadProducts() -> [Product] {
        if let data = UserDefaults.standard.data(forKey: productKey),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            return decoded
        }
        return []
    }
    
    func saveSessions(_ sessions: [Session]) {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    func loadSessions() -> [Session] {
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let decoded = try? JSONDecoder().decode([Session].self, from: data) {
            return decoded
        }
        return []
    }
    
    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: productKey)
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.synchronize()
    }
    
    func removeObject(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func findProduct(by barcode: String) -> Product? {
        let products = loadProducts()
        return products.first { $0.barcode == barcode }
    }
}

