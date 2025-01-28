//
//  Product.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import Foundation

struct Product: Identifiable, Codable {
    let id: UUID
    var name: String
    var price: Double
    var barcode: String
    var createdAt: Date
    var updatedAt: Date?
}
