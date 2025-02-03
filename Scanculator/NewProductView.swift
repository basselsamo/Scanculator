import SwiftUI

struct NewProductView: View {
    var barcode: String
    var onSave: (Product) -> Void

    @State private var productName: String = ""
    @State private var price: String = ""
    @State private var showingPriceError = false
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @FocusState private var isPriceFocused: Bool
    @State private var productWasFoundAutomatically = false
    @State private var productSource: ProductSource?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Product Header
                    VStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .padding(.top, 20)
                        
                        Text("New Product")
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack {
                            Image(systemName: "barcode")
                                .foregroundColor(.gray)
                            Text(barcode)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    
                    if isLoading {
                        ProgressView("Fetching product details...")
                            .padding()
                    } else {
                        // Product Details Form
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Product Name")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                if let source = productSource {
                                    Text("(\(source.rawValue))")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                TextField("Enter product name", text: $productName)
                                    .underlinedTextFieldStyle()
                                    .font(.body)
                                    .padding(.bottom, 8)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price (€)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                TextField("0.00", text: $price)
                                    .keyboardType(.decimalPad)
                                    .underlinedTextFieldStyle()
                                    .font(.body)
                                    .focused($isPriceFocused)
                            }
                        }
                        .padding()
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: saveProduct) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Product")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("No Product Found", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                fetchProductDetails()
            }
        }
        .alert("Invalid Price", isPresented: $showingPriceError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid price (e.g., 1,99 or 1.99)")
        }
    }
    
    private func fetchProductDetails() {
        isLoading = true
        
        Task {
            do {
                if let result = try await ProductLookupService.searchProduct(barcode: barcode) {
                    await MainActor.run {
                        self.productName = result.name
                        self.productSource = result.source
                        self.productWasFoundAutomatically = true
                        // Focus on price field after a short delay to ensure UI is ready
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            isPriceFocused = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Product not found in any database. Enter product details manually."
                    showingError = true
                    productWasFoundAutomatically = false
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func saveProduct() {
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        
        guard let priceValue = Double(normalizedPrice),
              priceValue >= 0,
              !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showingPriceError = true
            return
        }
        
        let product = Product(
            id: UUID(),
            name: productName.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceValue,
            barcode: barcode,
            createdAt: Date(),
            updatedAt: nil
        )
        
        onSave(product)
        presentationMode.wrappedValue.dismiss()
    }
}
