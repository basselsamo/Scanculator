import Foundation

enum BarcodeLookupError: Error {
    case productNotFound
    case invalidResponse
    case parsingError
}

class BarcodeLookupService {
    static func fetchProductData(barcode: String) async throws -> String? {
        let urlString = "https://www.barcodelookup.com/\(barcode)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add browser-like headers
        request.allHTTPHeaderFields = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Cache-Control": "max-age=0",
            "Referer": "https://www.google.com/"
        ]
        
//        print("Barcode Lookup URL: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BarcodeLookupError.invalidResponse
        }
        
//        print("Barcode Lookup status code: \(httpResponse.statusCode)")
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw BarcodeLookupError.parsingError
        }
        
        // Print first 500 characters of response for debugging
//        print("Barcode Lookup response preview: \(String(htmlString.prefix(500)))")
        
        // Check for "doesn't exist" message first
        if htmlString.contains("Barcode Doesn't Exist in Our Database") {
            print("Product not found in Barcodelookup.com database")
            throw BarcodeLookupError.productNotFound
        }
        
        // Update the patterns to better match the content
        let patterns = [
            // Match meta description content
            "<meta name=\"description\" content=\"[^-]+-\\s*([^.]+)\\.\"",
            // Match product title
            "<h4 class=\"product-title\">([^<]+)</h4>",
            // Match product name in meta description
            "<meta name=\"description\" content=\"[^\"]*?\\|\\s*([^\"]+)\"",
            // Match h1 title without EAN prefix
            "<h1[^>]*>(?:EAN\\s+\\d+\\s*\\|\\s*)?([^<]+)</h1>",
            // Match any text between EAN number and |
            "EAN\\s+\\d+\\s*-\\s*([^|]+)\\|"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
               let range = Range(match.range(at: 1), in: htmlString) {
                let productName = String(htmlString[range])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&#39;", with: "'")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "Barcode Lookup", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !productName.isEmpty && 
                   !productName.contains("EAN") && 
                   !productName.contains("Barcode Doesn't Exist") {
                    return productName
                }
            }
        }
        
        // If no pattern matched, try to extract from the meta description directly
        if let startIndex = htmlString.range(of: "content=\"Barcode Lookup provides info on EAN \\d+ - ")?.upperBound,
           let endIndex = htmlString[startIndex...].range(of: "\\.")?.lowerBound {
            let productName = String(htmlString[startIndex..<endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")
            
            if !productName.isEmpty && !productName.contains("Barcode Doesn't Exist") {
                return productName
            }
        }
        
        throw BarcodeLookupError.productNotFound
    }
} 
