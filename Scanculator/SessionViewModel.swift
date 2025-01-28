import Foundation
import SwiftUI

class SessionViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var products: [Product] = [] // Add the products array
    private var timers: [UUID: Timer] = [:]

    init() {
        loadSessions()
        loadProducts() // Load products when the view model initializes
    }

    // MARK: - Session Management
    func createSession(name: String) {
        let newSession = Session(
            id: UUID(),
            name: name,
            creationDate: Date(),
            isActive: true
        )
        sessions.insert(newSession, at: 0)
        startTimer(for: newSession.id)
        saveSessions()
    }

    func deleteSession(at indexSet: IndexSet) {
        indexSet.forEach { index in
            let session = sessions[index]
            stopTimer(for: session.id)
            sessions.remove(at: index)
        }
        saveSessions()
    }

    func endSession(_ session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index].isActive = false
            stopTimer(for: session.id)
            saveSessions()
        }
    }

    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "sessions")
        }
    }

    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "sessions"),
           let decoded = try? JSONDecoder().decode([Session].self, from: data) {
            sessions = decoded
        }
    }

    // MARK: - Product Management
    func addProduct(_ product: Product) {
        // Check if a product with the same barcode already exists
        if products.contains(where: { $0.barcode == product.barcode }) {
            print("Duplicate product detected. Product with barcode \(product.barcode) already exists.")
            return
        }
        products.append(product)
        saveProducts() // Save the updated product list
    }

    func findProduct(by barcode: String) -> Product? {
        return products.first { $0.barcode == barcode }
    }

    func saveProducts() {
        if let encoded = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(encoded, forKey: "products")
        }
    }

    func loadProducts() {
        if let data = UserDefaults.standard.data(forKey: "products"),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            products = decoded
        }
    }

    func addProductToSession(product: Product, quantity: Int, session: Binding<Session>) {
        if let index = sessions.firstIndex(where: { $0.id == session.wrappedValue.id }) {
            // Check if product already exists in session
            if let productIndex = sessions[index].products.firstIndex(where: { $0.product.id == product.id }) {
                // Update quantity of existing product
                sessions[index].products[productIndex].quantity += quantity
            } else {
                // Add new product to session
                let sessionProduct = SessionProduct(
                    id: UUID(),
                    product: product,
                    quantity: quantity,
                    unitPrice: product.price
                )
                sessions[index].products.append(sessionProduct)
            }
            saveSessions()
        }
    }

    // Add this new function to update product price in session
    func updateProductPriceInSession(sessionProduct: SessionProduct, newPrice: Double, session: Binding<Session>) {
        if let sessionIndex = sessions.firstIndex(where: { $0.id == session.wrappedValue.id }),
           let productIndex = sessions[sessionIndex].products.firstIndex(where: { $0.id == sessionProduct.id }) {
            sessions[sessionIndex].products[productIndex].unitPrice = newPrice
            sessions[sessionIndex].products[productIndex].priceWasCustomized = true
            saveSessions()
        }
    }

    // MARK: - Timer Management
    func startTimer(for sessionID: UUID) {
        guard timers[sessionID] == nil else { return } // Timer already exists
        if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
            timers[sessionID] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.saveSessions()
            }
        }
    }

    func stopTimer(for sessionID: UUID) {
        timers[sessionID]?.invalidate()
        timers[sessionID] = nil
    }
}
