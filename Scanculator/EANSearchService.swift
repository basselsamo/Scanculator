import Foundation

struct EANSearchProduct: Codable {
    let ean: String
    let name: String
    let categoryId: String?
    let categoryName: String?
    let issuingCountry: String?
    
    enum CodingKeys: String, CodingKey {
        case ean
        case name
        case categoryId = "categoryId"
        case categoryName = "categoryName"
        case issuingCountry = "issuingCountry"
    }
}

enum EANSearchError: Error {
    case productNotFound
    case invalidResponse
    case unauthorized
    case apiError(String)
}

class EANSearchService {
    // Update with your actual API token
    private static let apiToken = "7401009b32141e2150c5cc4c6cfb3eb373b3ce6c"
    
    static func fetchProductData(barcode: String) async throws -> String? {
        let urlString = "https://api.ean-search.org/api"
        var components = URLComponents(string: urlString)
        
        // Add query parameters
        components?.queryItems = [
            URLQueryItem(name: "token", value: apiToken),
            URLQueryItem(name: "op", value: "barcode-lookup"),
            URLQueryItem(name: "ean", value: barcode),
            URLQueryItem(name: "language", value: "3"), // German language code
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
//        print("EAN Search API URL: \(url)") // Add debug print
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EANSearchError.invalidResponse
        }
        
        // Add debug prints
//        print("EAN Search status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
//            print("EAN Search response: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let products = try decoder.decode([EANSearchProduct].self, from: data)
            
            guard let product = products.first else {
                throw EANSearchError.productNotFound
            }
            
            // Build product name with available information
            var components: [String] = []
            
            // Add name
            components.append(product.name)
            
            // Add category if available
            if let category = product.categoryName {
                components.append("[\(category)]")
            }
            
            return components.joined(separator: " ")
            
        case 401:
            throw EANSearchError.unauthorized
        default:
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error response: \(responseString)")
            }
            throw EANSearchError.apiError("HTTP Status: \(httpResponse.statusCode)")
        }
    }
} 
