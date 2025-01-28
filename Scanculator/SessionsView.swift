//
//  SessionsView.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import SwiftUI

struct SessionsView: View {
    @ObservedObject var viewModel: SessionViewModel
    @ObservedObject var productViewModel: ProductViewModel
    @State private var showingNewSessionSheet = false
    @State private var isFlashing = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(viewModel.sessions.indices, id: \.self) { index in
                        NavigationLink(
                            destination: SessionDetailView(
                                viewModel: viewModel,
                                productViewModel: productViewModel,
                                session: $viewModel.sessions[index]
                            )
                        ) {
                            SessionRowView(session: viewModel.sessions[index], isFlashing: isFlashing)
                        }
                    }
                    .onDelete(perform: viewModel.deleteSession)
                }
                
                if viewModel.sessions.isEmpty {
                    VStack {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Sessions")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap + to start a new shopping session")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Shopping Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingNewSessionSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Session")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewSessionSheet) {
            NewSessionView(viewModel: viewModel)
        }
        .onAppear {
            startFlashTimer()
        }
        .onDisappear {
            stopFlashTimer()
        }
    }
    
    private func startFlashTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation {
                isFlashing.toggle()
            }
        }
    }
    
    private func stopFlashTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct SessionRowView: View {
    let session: Session
    let isFlashing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.name)
                .font(.headline)
                .foregroundColor(session.isActive ? (isFlashing ? .red : .primary) : .primary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text(session.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("€\(String(format: "%.2f", session.totalEstimate))")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            if !session.products.isEmpty {
                Text("\(session.products.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionsView_Previews: PreviewProvider {
    static var previews: some View {
        SessionsView(viewModel: SessionViewModel(), productViewModel: ProductViewModel())
    }
}
