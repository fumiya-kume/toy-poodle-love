import SwiftUI

struct MapSpotMarker: View {
    let index: Int
    var isSelected: Bool = false
    var spotType: MapSpot.MapSpotType = .waypoint

    private var markerColor: Color {
        if isSelected { return .orange }
        switch spotType {
        case .start:
            return .green
        case .waypoint:
            return .accentColor
        case .destination:
            return .red
        }
    }

    var body: some View {
        Text("\(index)")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(6)
            .background(Circle().fill(markerColor))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HStack(spacing: 12) {
        MapSpotMarker(index: 1, isSelected: false, spotType: .start)
        MapSpotMarker(index: 2, isSelected: false, spotType: .waypoint)
        MapSpotMarker(index: 3, isSelected: false, spotType: .destination)
        MapSpotMarker(index: 4, isSelected: true, spotType: .waypoint)
    }
    .padding()
}
