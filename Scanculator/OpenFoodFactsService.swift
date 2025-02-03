import Foundation

struct OpenFoodFactsProduct: Codable {
    let status: Int
    let code: String
    let product: ProductData
    
    struct ProductData: Codable {
        let brands: String?
        let productName: String?
        let productNameDe: String?
        let quantity: String?
        
        enum CodingKeys: String, CodingKey {
            case brands
            case productName = "product_name"
            case productNameDe = "product_name_de"
            case quantity
        }
    }
}

// Add new product structs for other APIs
struct OutpanProduct: Codable {
    let name: String?
    let attributes: [String: String]?
}

struct DigitalProductsProduct: Codable {
    let name: String?
    let brand: String?
    let size: String?
}

enum OpenFoodFactsError: Error {
    case productNotFound
    case invalidResponse
}

enum ProductLookupError: Error {
    case productNotFound
    case invalidResponse
    case allSourcesFailed
}

enum ProductSource: String {
    case localDatabase = "Local Database"
    case barcodeLookup = "barcodelookup.com"
    case openFoodFacts = "Open Food Facts"
    case eanSearch = "EAN Search"
}

class OpenFoodFactsService {
    static func searchProduct(barcode: String) async throws -> String? {
        // Only use Open Food Facts API
        do {
            if let result = try await fetchProductData(barcode: barcode) {
                return result
            }
            throw OpenFoodFactsError.productNotFound
        } catch {
            print("Open Food Facts search failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func fetchProductData(barcode: String) async throws -> String? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        // Print response for debugging
//        print("Status code: \(httpResponse.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
//            print("API Response: \(jsonString)")
        }
        
        let product = try JSONDecoder().decode(OpenFoodFactsProduct.self, from: data)
        
        // Check if product was found
        if product.status == 0 {
            throw OpenFoodFactsError.productNotFound
        }
        
        // Combine the available information into a comprehensive product name
        var components: [String] = []
        
        // Add brand if available
        if let brand = product.product.brands?.trimmingCharacters(in: .whitespaces) {
            components.append(brand)
        }
        
        // Add product name (try German first, then fallback to default)
        if let name = product.product.productNameDe?.trimmingCharacters(in: .whitespaces) {
            components.append(name)
        } else if let name = product.product.productName?.trimmingCharacters(in: .whitespaces) {
            components.append(name)
        }
        
        // Add quantity if available
        if let quantity = product.product.quantity?.trimmingCharacters(in: .whitespaces) {
            components.append("(\(quantity))")
        }
        
        let combinedName = components.filter { !$0.isEmpty }.joined(separator: " ")
        return combinedName.isEmpty ? nil : combinedName
    }
}

class ProductLookupService {
    private static let eanSearchApiToken = "7401009b32141e2150c5cc4c6cfb3eb373b3ce6c"
    
    static func searchProduct(barcode: String) async throws -> (name: String, source: ProductSource)? {
        // 1. First check local database
        if let existingProduct = DataService.shared.findProduct(by: barcode) {
            print("Product found in local database")
            print("====================================")
            return (existingProduct.name, .localDatabase)
        }
        
        // 2. Try Barcode Lookup (free web scraping)
        do {
            print("Trying Barcodelookup.com...")
            if let result = try await BarcodeLookupService.fetchProductData(barcode: barcode) {
                print("Product found in Barcodeookup.com")
                print("====================================")
                return (result, .barcodeLookup)
            }
        } catch {
            print("Barcodelookup.com search failed: \(error.localizedDescription)")
        }
        
        // 3. Try Open Food Facts (free API)
        do {
            print("====================================")
            print("Trying Open Food Facts API...")
            if let result = try await OpenFoodFactsService.fetchProductData(barcode: barcode) {
                print("Product found in Open Food Facts API")
                print("====================================")
                return (result, .openFoodFacts)
            }
        } catch {
            print("Product not found in Open Food Facts API database")
            print("Open Food Facts API search failed: \(error.localizedDescription)")
        }
        
        // 4. Try EAN Search as last resort (paid API, preserve quota)
        do {
            print("====================================")
            print("Trying EAN-Search.org as last resort...")
            if let result = try await EANSearchService.fetchProductData(barcode: barcode) {
                print("Product found in EAN-Search.org")
                print("====================================")
                return (result, .eanSearch)
            }
        } catch {
            print("Product not found in EAN-Search.org database")
            print("EAN-Search.org search failed: \(error.localizedDescription)")
            print("====================================")
        }
        
        throw ProductLookupError.allSourcesFailed
    }
} 
