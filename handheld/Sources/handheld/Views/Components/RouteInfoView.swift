import SwiftUI

struct RouteInfoView: View {
    let route: Route
    var hasLookAroundAvailable: Bool = false
    var onLookAroundTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 24) {
            Label {
                Text(route.formattedDistance)
                    .font(.headline)
            } icon: {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
            }

            Label {
                Text(route.formattedTravelTime)
                    .font(.headline)
            } icon: {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
            }

            Spacer()

            if let onLookAroundTap = onLookAroundTap {
                Button(action: onLookAroundTap) {
                    Image(systemName: "binoculars.fill")
                        .font(.title2)
                        .foregroundColor(hasLookAroundAvailable ? .blue : .gray)
                }
                .disabled(!hasLookAroundAvailable)
                .accessibilityLabel("Look Aroundを表示")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    RouteInfoView(route: Route(mkRoute: .init()))
        .padding()
}
