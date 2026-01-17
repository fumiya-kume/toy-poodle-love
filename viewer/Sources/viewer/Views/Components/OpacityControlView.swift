import SwiftUI

struct OpacityControlView: View {
    @Binding var opacity: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.lefthalf.filled")
                .foregroundStyle(.secondary)
                .font(.system(size: 14))

            Slider(value: $opacity, in: 0...1, step: 0.01)
                .frame(width: 200)

            Text("\(Int(opacity * 100))%")
                .monospacedDigit()
                .frame(width: 45, alignment: .trailing)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    OpacityControlView(opacity: .constant(0.5))
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
