import Foundation

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []

    func addProduct(_ product: Product) {
        products.append(product) // Add the product to the in-memory array
        saveProducts()           // Persist to UserDefaults
        loadProducts()           // Reload the in-memory array from UserDefaults
    }

    func deleteProduct(at offsets: IndexSet) {
        products.remove(atOffsets: offsets)
        saveProducts()
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

    func updateProduct(_ updatedProduct: Product) {
        if let index = products.firstIndex(where: { $0.id == updatedProduct.id }) {
            products[index] = updatedProduct
            saveProducts()
        }
    }

    func deleteProduct(_ product: Product) {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products.remove(at: index)
            saveProducts()
        }
    }

    init() {
        loadProducts()
    }
}
