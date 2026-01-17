import SwiftUI

struct RouteInfoView: View {
    let route: Route
    @Binding var transportType: TransportType
    var hasLookAroundAvailable: Bool = false
    var onLookAroundTap: (() -> Void)?
    var onTransportTypeChange: (() -> Void)?
    var onStartNavigation: (() -> Void)?
    var onStartAutoDrive: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Picker("交通手段", selection: $transportType) {
                    ForEach(TransportType.allCases) { type in
                        Image(systemName: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .onChange(of: transportType) {
                    onTransportTypeChange?()
                }

                Label {
                    Text(route.formattedDistance)
                        .font(.headline)
                } icon: {
                    Image(systemName: transportType.icon)
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

            HStack(spacing: 12) {
                if let onStartNavigation = onStartNavigation {
                    Button(action: onStartNavigation) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("ナビ開始")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }

                if let onStartAutoDrive = onStartAutoDrive, hasLookAroundAvailable {
                    Button(action: onStartAutoDrive) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("自動再生")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    RouteInfoView(
        route: Route(mkRoute: .init()),
        transportType: .constant(.automobile)
    )
    .padding()
}
