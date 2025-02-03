import SwiftUI

struct UnderlinedTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .background(
                VStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
            )
            .padding(.bottom, 4)
    }
}

extension View {
    func underlinedTextFieldStyle() -> some View {
        modifier(UnderlinedTextFieldStyle())
    }
} 