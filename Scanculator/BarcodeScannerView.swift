//
//  BarcodeScannerView.swift
//  Scanculator
//
//  Created by Bassel Samo on 27.01.25.
//

import SwiftUI
import CodeScanner
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var scannedBarcode: String?
    @Binding var quantity: Int
    var showQuantity: Bool
    @State private var isTorchOn = false
    
    init(scannedBarcode: Binding<String?>, quantity: Binding<Int> = .constant(1), showQuantity: Bool = true) {
        self._scannedBarcode = scannedBarcode
        self._quantity = quantity
        self.showQuantity = showQuantity
    }
    
    var body: some View {
        VStack {
            if showQuantity {
                HStack {
                    Text("Quantity")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 20) {
                        Button(action: {
                            if quantity > 1 {
                                quantity -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        
                        Text("\(quantity)")
                            .font(.headline)
                        
                        Button(action: {
                            quantity += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                    }
                }
                .padding()
                .background(Color.white)
            }
            
            // Scanner with optimized settings
            CodeScannerView(
                codeTypes: [.ean8, .ean13, .upce],
                scanMode: .continuous,
                scanInterval: 0.2,
                showViewfinder: true,
                shouldVibrateOnSuccess: true,
                isTorchOn: isTorchOn,
                isGalleryPresented: .constant(false),
                videoCaptureDevice: AVCaptureDevice.default(for: .video),
                completion: handleScan
            )
            
            // Flashlight toggle button
            Button(action: {
                isTorchOn.toggle()
            }) {
                HStack {
                    Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .foregroundColor(isTorchOn ? .yellow : .gray)
                    Text(isTorchOn ? "Turn Off Flash" : "Turn On Flash")
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.bottom)
            }
        }
        .navigationTitle("Scan Barcode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let result):
            // Play scanner beep sound
            AudioServicesPlaySystemSound(1103)
            scannedBarcode = result.string
            presentationMode.wrappedValue.dismiss()
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}
