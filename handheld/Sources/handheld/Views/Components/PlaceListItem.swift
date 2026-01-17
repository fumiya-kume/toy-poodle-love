import SwiftUI

struct PlaceListItem: View {
    let place: Place

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(place.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        PlaceListItem(place: Place(mapItem: .init(placemark: .init(coordinate: .init(latitude: 35.6812, longitude: 139.7671)))))
    }
}
