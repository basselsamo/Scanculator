//
//  SettingsView.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import SwiftUI

struct SettingsView: View {
//    @AppStorage("currency") private var currency = "€"
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteSessionsAlert = false
    @State private var showingDeleteProductsAlert = false
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var productViewModel: ProductViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    HStack {
                        Image(systemName: "eurosign.circle.fill")
                            .foregroundColor(.blue)
                        Text("Currency")
                        Spacer()
                        Text("€")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text("Developer")
                        Spacer()
                        Text("Bassel Samo")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: { showingDeleteSessionsAlert = true }) {
                        HStack {
                            Image(systemName: "cart.circle.fill")
                                .foregroundColor(.red)
                            Text("Delete All Sessions")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: { showingDeleteProductsAlert = true }) {
                        HStack {
                            Image(systemName: "tag.circle.fill")
                                .foregroundColor(.red)
                            Text("Delete All Products")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: { showingDeleteAllAlert = true }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            Text("Delete All App Data")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Delete All Sessions?", isPresented: $showingDeleteSessionsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                DataService.shared.removeObject(forKey: "sessions")
                sessionViewModel.sessions = []
            }
        } message: {
            Text("This will delete all shopping sessions. This action cannot be undone.")
        }
        .alert("Delete All Products?", isPresented: $showingDeleteProductsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                DataService.shared.removeObject(forKey: "products")
                productViewModel.products = []
            }
        } message: {
            Text("This will delete all products from the database. This action cannot be undone.")
        }
        .alert("Reset All Data?", isPresented: $showingDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                DataService.shared.resetAllData()
                sessionViewModel.sessions = []
                productViewModel.products = []
            }
        } message: {
            Text("This will delete all products and sessions. This action cannot be undone.")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            sessionViewModel: SessionViewModel(),
            productViewModel: ProductViewModel()
        )
    }
}

