import SwiftUI

struct NewProductView: View {
    var barcode: String
    var onSave: (Product) -> Void

    @State private var productName: String = ""
    @State private var price: String = ""
    @State private var showingPriceError = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Product Header
                    VStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                        
                        Text("New Product")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(barcode)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    
                    // Product Details Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Name")
                                .font(.headline)
                                .foregroundColor(.gray)
                            TextField("Enter product name", text: $productName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Price (€)")
                                .font(.headline)
                                .foregroundColor(.gray)
                            TextField("0.00", text: $price)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                    }
                    .padding()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
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
                        
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Invalid Price", isPresented: $showingPriceError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid price (e.g., 1,99 or 1.99)")
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
