import SwiftUI
import MapKit

struct AutoDriveLoadingView: View {
    let progress: Double
    let fetchedCount: Int
    let totalCount: Int
    let points: [RouteCoordinatePoint]
    let route: Route?
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let route = route {
                mapView(route: route)
            }

            progressSection

            cancelButton
        }
        .padding()
    }

    private func mapView(route: Route) -> some View {
        Map {
            MapPolyline(route.polyline)
                .stroke(.blue, lineWidth: 4)

            ForEach(points) { point in
                if !point.isLookAroundLoading {
                    Annotation("", coordinate: point.coordinate) {
                        Circle()
                            .fill(point.hasScene ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .frame(height: 250)
        .cornerRadius(12)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            Text("シーンを取得中... \(fetchedCount)/\(totalCount)")
                .font(.headline)

            ProgressView(value: progress)
                .tint(.blue)
        }
    }

    private var cancelButton: some View {
        Button("キャンセル") {
            onCancel()
        }
        .buttonStyle(.bordered)
    }
}
