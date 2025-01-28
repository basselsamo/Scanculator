//
//  NewSessionView.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import SwiftUI

struct NewSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SessionViewModel
    @State private var sessionName: String = ""
    
    private func getDefaultSessionName() -> String {
        let existingSessions = viewModel.sessions.filter { $0.name.starts(with: "New Session") }
        let numbers = existingSessions.compactMap { session -> Int? in
            let components = session.name.components(separatedBy: " ")
            guard components.count == 3 else { return nil }
            return Int(components[2])
        }
        let nextNumber = (numbers.max() ?? 0) + 1
        return "New Session \(nextNumber)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("New Shopping Session")
                    .font(.title2.bold())
                
                Text("Give your shopping session a name")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            
            // Session Name Input
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Name")
                        .font(.headline)
                        .foregroundColor(.gray)
                    TextField("Enter session name", text: $sessionName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .padding(.bottom, 8)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        let name = sessionName.isEmpty ? getDefaultSessionName() : sessionName
                        viewModel.createSession(name: name)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Start Session")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
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
    }
}

struct NewSessionView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionView(viewModel: SessionViewModel())
            .preferredColorScheme(.light)
        
        NewSessionView(viewModel: SessionViewModel())
            .preferredColorScheme(.dark)
    }
}
