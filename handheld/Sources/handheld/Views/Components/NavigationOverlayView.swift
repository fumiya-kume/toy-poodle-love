import SwiftUI
import MapKit

struct NavigationOverlayView: View {
    let currentStep: NavigationStep?
    let distanceToNextStep: String
    var onStopNavigation: (() -> Void)?
    var onLookAroundTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let step = currentStep {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(distanceToNextStep)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.primary)

                            Text(step.displayInstructions)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        if step.lookAroundScene != nil {
                            Button(action: { onLookAroundTap?() }) {
                                Image(systemName: "binoculars.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                    }

                    if step.isLookAroundLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Look Around読み込み中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }

            Spacer()

            Button(action: { onStopNavigation?() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("ナビ終了")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(25)
                .shadow(radius: 4)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationOverlayView(
        currentStep: nil,
        distanceToNextStep: "150 m"
    )
}
