import SwiftUI

struct ContentView: View {
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var productViewModel = ProductViewModel() // Shared instance

    var body: some View {
        TabView {
            SessionsView(viewModel: sessionViewModel, productViewModel: productViewModel) // Pass ProductViewModel
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }
            ProductsView(viewModel: productViewModel)
                .tabItem {
                    Label("Products", systemImage: "cart")
                }
            SettingsView(sessionViewModel: sessionViewModel, productViewModel: productViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
