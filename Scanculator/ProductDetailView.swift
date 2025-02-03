//
//  ProductDetailView.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import SwiftUI
import Charts

struct PriceHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

struct ProductDetailView: View {
    @ObservedObject var viewModel: ProductViewModel
    @State var product: Product
    @State private var showingEditSheet = false
    @State private var editedName: String = ""
    @State private var editedPrice: String = ""
    @State private var showingDeleteAlert = false
    @State private var showingPriceError = false
    @Environment(\.presentationMode) var presentationMode
    
    private var priceHistory: [PriceHistoryPoint] {
        // Get all sessions that contain this product
        let sessions = DataService.shared.loadSessions()
        
        // Extract price points from sessions
        let pricePoints = sessions.compactMap { session -> PriceHistoryPoint? in
            if let sessionProduct = session.products.first(where: { $0.product.id == product.id }) {
                return PriceHistoryPoint(date: session.creationDate, price: sessionProduct.unitPrice)
            }
            return nil
        }
        
        // Sort by date and return
        return pricePoints.sorted { $0.date < $1.date }
    }
    
    private var averagePrice: Double {
        guard !priceHistory.isEmpty else { return product.price }
        return priceHistory.reduce(0) { $0 + $1.price } / Double(priceHistory.count)
    }
    
    private var priceRange: (min: Double, max: Double) {
        guard !priceHistory.isEmpty else { return (product.price, product.price) }
        let prices = priceHistory.map { $0.price }
        return (prices.min() ?? product.price, prices.max() ?? product.price)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(product.name)
                            .font(.title2.bold())
                        Spacer()
                        Text("€\(String(format: "%.2f", product.price))")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundColor(.gray)
                        Text(product.barcode)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Price History Chart
                if !priceHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Price History")
                            .font(.headline)
                        
                        Chart {
                            ForEach(priceHistory) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Price", point.price)
                                )
                                .foregroundStyle(.blue)
                                
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Price", point.price)
                                )
                                .foregroundStyle(.blue)
                            }
                            
                            RuleMark(
                                y: .value("Average", averagePrice)
                            )
                            .foregroundStyle(.gray.opacity(0.5))
                            .lineStyle(StrokeStyle(dash: [5, 5]))
                        }
                        .frame(height: 200)
                        .chartYScale(domain: priceRange.min * 0.9...priceRange.max * 1.1)
                        
                        // Price Statistics
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Average Price:")
                                Text("€\(String(format: "%.2f", averagePrice))")
                                    .foregroundColor(.gray)
                            }
                            HStack {
                                Text("Lowest Price:")
                                Text("€\(String(format: "%.2f", priceRange.min))")
                                    .foregroundColor(.green)
                            }
                            HStack {
                                Text("Highest Price:")
                                Text("€\(String(format: "%.2f", priceRange.max))")
                                    .foregroundColor(.red)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showingEditSheet = true }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                            Text("Edit Product")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("Delete Product")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    Text("Edit Product")
                        .font(.title2.bold())
                    
                    Text("Update product details")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                
                // Product Details Input
                VStack() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Product Name")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Enter product name", text: $editedName)
                            .underlinedTextFieldStyle()
                            .font(.body)
                            .padding(.bottom, 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Enter price", text: $editedPrice)
                            .underlinedTextFieldStyle()
                            .font(.body)
                            .keyboardType(.decimalPad)
                            .padding(.bottom, 8)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            saveChanges()
                            showingEditSheet = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Changes")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingEditSheet = false
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(UIColor.systemBackground))
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
            .onAppear {
                editedName = product.name
                editedPrice = String(format: "%.2f", product.price)
            }
        }
        .alert("Invalid Price", isPresented: $showingPriceError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid price (e.g., 1,99 or 1.99)")
        }
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProduct()
            }
        } message: {
            Text("Are you sure you want to delete this product? This action cannot be undone.")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func startEditing() {
        editedName = product.name
        editedPrice = String(format: "%.2f", product.price)
        showingEditSheet = true
    }
    
    private func saveChanges() {
        guard let newPrice = Double(editedPrice.replacingOccurrences(of: ",", with: ".")),
              newPrice >= 0 else {
            showingPriceError = true
            return
        }
        
        let updatedProduct = Product(
            id: product.id,
            name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
            price: newPrice,
            barcode: product.barcode,
            createdAt: product.createdAt,
            updatedAt: Date()
        )
        
        viewModel.updateProduct(updatedProduct)
        product = updatedProduct
        showingEditSheet = false
    }
    
    private func cancelEdit() {
        showingEditSheet = false
    }
    
    private func deleteProduct() {
        viewModel.deleteProduct(product)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailView(viewModel: ProductViewModel(), product: Product(
            id: UUID(),
            name: "Sample Product",
            price: 12.99,
            barcode: "1234567890123",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
