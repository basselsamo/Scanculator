//
//  ScanculatorApp.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import SwiftUI

@main
struct ScanculatorApp: App {
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var productViewModel = ProductViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionViewModel)
                .environmentObject(productViewModel)
        }
    }
}
