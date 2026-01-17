import SwiftUI

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        StepIndicator(currentStep: 0, totalSteps: 4)
        StepIndicator(currentStep: 1, totalSteps: 4)
        StepIndicator(currentStep: 2, totalSteps: 4)
        StepIndicator(currentStep: 3, totalSteps: 4)
    }
}
