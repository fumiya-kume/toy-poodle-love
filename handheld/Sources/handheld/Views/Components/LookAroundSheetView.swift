import SwiftUI
import MapKit

struct LookAroundSheetView: View {
    @Binding var selectedTarget: LookAroundTarget
    let destinationScene: MKLookAroundScene?
    let nextStepScene: MKLookAroundScene?
    let destinationName: String
    let hasNextStep: Bool

    private var availableTargets: [LookAroundTarget] {
        var targets: [LookAroundTarget] = []
        if destinationScene != nil {
            targets.append(.destination)
        }
        if hasNextStep && nextStepScene != nil {
            targets.append(.nextStep)
        }
        return targets
    }

    private var currentScene: MKLookAroundScene? {
        switch selectedTarget {
        case .destination:
            return destinationScene
        case .nextStep:
            return nextStepScene
        }
    }

    private var showSegmentControl: Bool {
        hasNextStep && (destinationScene != nil || nextStepScene != nil)
    }

    var body: some View {
        VStack(spacing: 16) {
            if showSegmentControl {
                Picker("表示地点", selection: $selectedTarget) {
                    ForEach(LookAroundTarget.allCases) { target in
                        Text(target.rawValue)
                            .tag(target)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(!isTargetAvailable(selectedTarget))
            }

            if let scene = currentScene {
                LookAroundPreview(initialScene: scene)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "利用不可",
                    systemImage: "eye.slash",
                    description: Text("この地点ではLook Aroundを利用できません")
                )
            }

            Spacer()
        }
        .padding(.top, 16)
        .onChange(of: selectedTarget) { _, newValue in
            if !isTargetAvailable(newValue), let firstAvailable = availableTargets.first {
                selectedTarget = firstAvailable
            }
        }
    }

    private func isTargetAvailable(_ target: LookAroundTarget) -> Bool {
        switch target {
        case .destination:
            return destinationScene != nil
        case .nextStep:
            return hasNextStep && nextStepScene != nil
        }
    }
}

#Preview {
    @Previewable @State var target: LookAroundTarget = .destination

    LookAroundSheetView(
        selectedTarget: $target,
        destinationScene: nil,
        nextStepScene: nil,
        destinationName: "東京タワー",
        hasNextStep: true
    )
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
}
