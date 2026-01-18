import MapKit
import SwiftUI

/// Scenario Writer map tab
struct ScenarioMapTab: View {
    @Environment(AppState.self) private var appState
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selectedSpotID: MapSpot.ID?

    private var mapSpots: [MapSpot] {
        appState.scenarioWriterState.mapSpots
    }

    private var selectedSpot: MapSpot? {
        guard let selectedSpotID else { return nil }
        return mapSpots.first { $0.id == selectedSpotID }
    }

    var body: some View {
        Group {
            if mapSpots.isEmpty {
                emptyStateView
            } else {
                mapView
                    .overlay(alignment: .bottom) {
                        infoPanel
                    }
            }
        }
        .onAppear {
            updateRegion(for: mapSpots)
        }
        .onChange(of: mapSpots) { newValue in
            selectedSpotID = nil
            updateRegion(for: newValue)
        }
    }

    private var mapView: some View {
        let baseMap = Map(
            coordinateRegion: $region,
            interactionModes: .all,
            annotationItems: mapSpots
        ) { spot in
            MapAnnotation(coordinate: spot.coordinate) {
                Button {
                    selectedSpotID = spot.id
                } label: {
                    MapSpotMarker(
                        index: spot.order,
                        isSelected: spot.id == selectedSpotID,
                        spotType: spot.type
                    )
                }
                .buttonStyle(.plain)
            }
        }

        if #available(macOS 14.0, *) {
            return AnyView(
                baseMap
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                        MapZoomStepper()
                    }
            )
        }

        return AnyView(baseMap)
    }

    @ViewBuilder
    private var infoPanel: some View {
        if let spot = selectedSpot {
            VStack(alignment: .leading, spacing: 6) {
                Text(spot.name)
                    .font(.headline)

                if let address = spot.address, !address.isEmpty {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let description = spot.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: 420, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            Text("マップに表示するデータがありません")
                .font(.headline)
            Text("Pipelineを実行して「マップで表示」をクリックしてください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func updateRegion(for spots: [MapSpot]) {
        guard !spots.isEmpty else { return }

        let latitudes = spots.map { $0.coordinate.latitude }
        let longitudes = spots.map { $0.coordinate.longitude }

        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.35, 0.01)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.35, 0.01)

        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}

#Preview {
    ScenarioMapTab()
        .environment(AppState())
        .frame(width: 700, height: 500)
}
