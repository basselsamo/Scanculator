import SwiftUI

struct ProductsView: View {
    @ObservedObject var viewModel: ProductViewModel
    @State private var showingNewProductSheet = false
    @State private var showingScanner = false
    @State private var scannedBarcode: String?
    @State private var searchText = ""
    @State private var showingDuplicateAlert = false
    
    var filteredProducts: [Product] {
        let products = if searchText.isEmpty {
            viewModel.products
        } else {
            viewModel.products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.barcode.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return products.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(filteredProducts) { product in
                        NavigationLink(
                            destination: ProductDetailView(viewModel: viewModel, product: product)
                        ) {
                            ProductRowView(product: product)
                        }
                    }
                    .onDelete { indexSet in
                        // Convert filtered index to actual index
                        let productsToDelete = indexSet.map { filteredProducts[$0] }
                        for product in productsToDelete {
                            if let index = viewModel.products.firstIndex(where: { $0.id == product.id }) {
                                viewModel.products.remove(at: index)
                            }
                        }
                        viewModel.saveProducts()
                    }
                }
                
                if viewModel.products.isEmpty {
                    VStack {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Products")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap + to add a new product")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Products")
            .searchable(text: $searchText, prompt: "Search products")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Product")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView(
                scannedBarcode: $scannedBarcode,
                quantity: .constant(1),
                showQuantity: false
            )
        }
        .sheet(isPresented: $showingNewProductSheet) {
            if let barcode = scannedBarcode {
                NewProductView(
                    barcode: barcode,
                    onSave: { newProduct in
                        viewModel.addProduct(newProduct)
                        scannedBarcode = nil
                    }
                )
            }
        }
        .onChange(of: scannedBarcode) { newValue in
            if let barcode = newValue {
                if let existingProduct = viewModel.products.first(where: { $0.barcode == barcode }) {
                    showingDuplicateAlert = true
                    scannedBarcode = nil
                } else {
                    showingNewProductSheet = true
                }
            }
        }
        .alert("Duplicate Barcode", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A product with this barcode already exists in the database.")
        }
    }
}

struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "barcode")
                    .foregroundColor(.gray)
                Text(product.barcode)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("€\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
