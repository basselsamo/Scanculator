import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var viewModel: SessionViewModel
    @ObservedObject var productViewModel: ProductViewModel
    @Binding var session: Session
    @State private var isShowingScanner = false
    @State private var isAddingNewProduct = false
    @State private var scannedBarcode: String? = nil
    @State private var scannedQuantity: Int = 1
    @State private var showingProductNotFoundAlert = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAbortAlert = false
    @State private var showingEndAlert = false
    @State private var isFlashing = false
    @State private var flashTimer: Timer? = nil
    @State private var showingDuplicateProductAlert = false

    var body: some View {
        VStack(spacing: 0) {
            sessionHeaderView
            
            if session.products.isEmpty {
                emptyStateView
            } else {
                productListView
            }
            
            if session.isActive {
                scanButtonView
            }
        }
        .navigationTitle(session.name)
        .navigationBarItems(
            leading: leadingNavigationButton,
            trailing: trailingNavigationButton
        )
        .alert(session.isActive ? "Abort Session?" : "Delete Session?", isPresented: $showingAbortAlert) {
            Button("Cancel", role: .cancel) { }
            Button(session.isActive ? "Abort" : "Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text(session.isActive ? 
                "This will delete the current session and all its data. This action cannot be undone." :
                "Are you sure you want to delete this session? This action cannot be undone.")
        }
        .alert("End Session?", isPresented: $showingEndAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Session") {
                endSession()
            }
        } message: {
            Text("This will end the current shopping session. You won't be able to add more items.")
        }
        .alert("Product Already in Cart", isPresented: $showingDuplicateProductAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Add Anyway") {
                // Add another instance of the product
            }
        } message: {
            Text("This product is already in your cart. Do you want to add it again?")
        }
        .alert("Product Not Found", isPresented: $showingProductNotFoundAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This product is not in the database. Please add it first.")
        }
        .onAppear {
            if session.isActive {
                startFlashTimer()
            }
        }
        .onDisappear {
            stopFlashTimer()
        }
        .sheet(isPresented: $isShowingScanner, onDismiss: handleScannerDismiss) {
            BarcodeScannerView(
                scannedBarcode: $scannedBarcode,
                quantity: $scannedQuantity
            )
        }
        .sheet(isPresented: $isAddingNewProduct) {
            if let barcode = scannedBarcode {
                NewProductView(barcode: barcode) { newProduct in
                    productViewModel.addProduct(newProduct)
                    viewModel.addProductToSession(
                        product: newProduct,
                        quantity: scannedQuantity,
                        session: $session
                    )
                    scannedBarcode = nil
                    isAddingNewProduct = false
                }
            }
        }
    }
    
    // MARK: - Subviews
    private var sessionHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started: \(session.formattedDate)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack {
                Text(session.isActive ? "Current Estimate" : "Final Estimate")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("€\(String(format: "%.2f", session.totalEstimate))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(session.isActive ? (isFlashing ? Color.red.opacity(0.15) : Color.clear) : Color.clear)
        .animation(.easeInOut(duration: 0.5), value: isFlashing)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Products")
                .font(.title2)
                .foregroundColor(.gray)
            if session.isActive {
                Text("Tap the scan button to add products")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            } else {
                Text("This session has no products")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var productListView: some View {
        List {
            ForEach(session.products.indices, id: \.self) { index in
                ProductRowView(
                    product: session.products[index],
                    onQuantityChange: { newQuantity in
                        session.products[index].quantity = newQuantity
                        viewModel.saveSessions()
                    },
                    onPriceChange: { newPrice in
                        viewModel.updateProductPriceInSession(
                            sessionProduct: session.products[index],
                            newPrice: newPrice,
                            session: $session
                        )
                        
                        if session.isActive {
                            var updatedProduct = session.products[index].product
                            updatedProduct.price = newPrice
                            updatedProduct.updatedAt = Date()
                            productViewModel.updateProduct(updatedProduct)
                        }
                    },
                    isSessionActive: session.isActive
                )
            }
            .onDelete(perform: session.isActive ? { indexSet in
                withAnimation {
                    session.products.remove(atOffsets: indexSet)
                    viewModel.saveSessions()
                }
            } : nil)
        }
    }
    
    private var scanButtonView: some View {
        Button(action: {
            isShowingScanner = true
        }) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                Text("Scan Product")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .padding()
        }
    }
    
    private var leadingNavigationButton: some View {
        Group {
            if session.isActive {
                Button("Abort Session") {
                    showingAbortAlert = true
                }
            }
        }
    }
    
    private var trailingNavigationButton: some View {
        Group {
            if session.isActive {
                Button("End Session") {
                    showingEndAlert = true
                }
            } else {
                Button("Delete") {
                    showingAbortAlert = true
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private struct ProductRowView: View {
        let product: SessionProduct
        var onQuantityChange: (Int) -> Void
        var onPriceChange: (Double) -> Void
        @State private var showingAdjustment = false
        @State private var currentPrice: Double
        @State private var currentQuantity: Int
        @State private var priceText: String = ""
        let isSessionActive: Bool
        
        init(product: SessionProduct, 
             onQuantityChange: @escaping (Int) -> Void, 
             onPriceChange: @escaping (Double) -> Void,
             isSessionActive: Bool) {
            self.product = product
            self.onQuantityChange = onQuantityChange
            self.onPriceChange = onPriceChange
            self.isSessionActive = isSessionActive
            _currentPrice = State(initialValue: product.unitPrice)
            _currentQuantity = State(initialValue: product.quantity)
        }
        
        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.product.name)
                        .font(.headline)
                    HStack {
                        Text("€\(String(format: "%.2f", product.unitPrice))")
                            .foregroundColor(.gray)
                        Text("×")
                            .foregroundColor(.gray)
                        Text("\(product.quantity)")
                            .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("€\(String(format: "%.2f", product.totalPrice))")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if isSessionActive {
                        Button(action: {
                            currentPrice = product.unitPrice
                            currentQuantity = product.quantity
                            showingAdjustment = true
                        }) {
                            Text("Tap to Adjust")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .sheet(isPresented: $showingAdjustment) {
                NavigationView {
                    VStack(spacing: 0) {
                        // Product Info Header
                        VStack(spacing: 8) {
                            Text(product.product.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Barcode: \(product.product.barcode)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        
                        Form {
                            Section(header: Text("Quantity")) {
                                HStack {
                                    Text("Current Quantity: \(currentQuantity)")
                                    Spacer()
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            if currentQuantity > 1 {
                                                withAnimation {
                                                    currentQuantity -= 1
                                                }
                                                onQuantityChange(currentQuantity)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.blue)
                                                .imageScale(.large)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation {
                                                currentQuantity += 1
                                            }
                                            onQuantityChange(currentQuantity)
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.blue)
                                                .imageScale(.large)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                            
                            Section(header: Text("Unit Price")) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Price: €\(String(format: "%.2f", currentPrice))")
                                        .foregroundColor(.gray)
                                    
                                    TextField("Enter price", text: $priceText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.body)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: priceText) { newValue in
                                            if let newPrice = Double(newValue.replacingOccurrences(of: ",", with: ".")),
                                               newPrice >= 0 {
                                                currentPrice = (newPrice * 100).rounded() / 100
                                                onPriceChange(currentPrice)
                                            }
                                        }
                                }
                            }
                            
                            Section {
                                HStack {
                                    Text("Total")
                                        .font(.headline)
                                    Spacer()
                                    Text("€\(String(format: "%.2f", currentPrice * Double(currentQuantity)))")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .navigationTitle("Adjust Product")
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showingAdjustment = false
                        }
                    )
                    .onAppear {
                        priceText = String(format: "%.2f", currentPrice)
                    }
                }
            }
        }
    }

    // MARK: - Flash Timer Logic
    private func startFlashTimer() {
        flashTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            isFlashing.toggle()
        }
    }
    
    private func stopFlashTimer() {
        flashTimer?.invalidate()
        flashTimer = nil
    }

    // MARK: - Session Actions
    private func endSession() {
        session.isActive = false
        viewModel.endSession(session)
        stopFlashTimer()
    }

    private func deleteSession() {
        if let index = viewModel.sessions.firstIndex(where: { $0.id == session.id }) {
            viewModel.sessions.remove(at: index)
            viewModel.saveSessions()
            stopFlashTimer()
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func handleScannerDismiss() {
        if let barcode = scannedBarcode {
            productViewModel.loadProducts()
            
            if let existingProduct = productViewModel.products.first(where: { $0.barcode == barcode }) {
                viewModel.addProductToSession(
                    product: existingProduct,
                    quantity: scannedQuantity,
                    session: $session
                )
            } else {
                isAddingNewProduct = true
            }
        }
        scannedQuantity = 1
    }
}
