import SwiftUI
import MapKit

struct PlanMapView: View {
    @Bindable var viewModel: PlanGeneratorViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(Array(viewModel.generatedSpots.enumerated()), id: \.element.id) { index, spot in
                Annotation(
                    spot.name,
                    coordinate: spot.coordinate,
                    anchor: .bottom
                ) {
                    SpotMarker(
                        index: index + 1,
                        isSelected: viewModel.selectedSpotForDetail?.id == spot.id
                    )
                    .onTapGesture {
                        viewModel.showSpotDetail(spot)
                    }
                }
            }

            ForEach(viewModel.routePolylines, id: \.hash) { polyline in
                MapPolyline(polyline)
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            fitMapToSpots()
        }
    }

    private func fitMapToSpots() {
        guard !viewModel.generatedSpots.isEmpty else { return }

        let coordinates = viewModel.generatedSpots.map { $0.coordinate }
        let minLat = coordinates.map(\.latitude).min() ?? 0
        let maxLat = coordinates.map(\.latitude).max() ?? 0
        let minLon = coordinates.map(\.longitude).min() ?? 0
        let maxLon = coordinates.map(\.longitude).max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5 + 0.01,
            longitudeDelta: (maxLon - minLon) * 1.5 + 0.01
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct SpotMarker: View {
    let index: Int
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.orange : Color.accentColor)
                .frame(width: 32, height: 32)
                .shadow(radius: 2)

            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    PlanMapView(viewModel: PlanGeneratorViewModel())
}
