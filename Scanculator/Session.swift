//
//  Session.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import Foundation

struct Session: Identifiable, Codable {
    let id: UUID
    var name: String
    let creationDate: Date
    var products: [SessionProduct] = []
    var isActive: Bool = true
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
    
    var totalEstimate: Double {
        products.reduce(0) { $0 + $1.totalPrice }
    }
}

struct SessionProduct: Identifiable, Codable {
    let id: UUID
    var product: Product
    var quantity: Int
    var unitPrice: Double
    var priceWasCustomized: Bool = false
    
    var totalPrice: Double {
        Double(quantity) * unitPrice
    }
}
