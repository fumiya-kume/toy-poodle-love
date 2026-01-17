import CoreLocation
import Foundation
import os

/// ジオコーディング結果を表すモデル
struct GeocodedPlace: Identifiable, Equatable {
    let id: UUID
    let originalAddress: String
    let resolvedAddress: String
    let coordinate: CLLocationCoordinate2D

    init(originalAddress: String, resolvedAddress: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.originalAddress = originalAddress
        self.resolvedAddress = resolvedAddress
        self.coordinate = coordinate
    }

    static func == (lhs: GeocodedPlace, rhs: GeocodedPlace) -> Bool {
        lhs.id == rhs.id
    }
}

protocol GeocodingServiceProtocol {
    /// 住所から緯度経度を取得する
    func geocode(address: String) async throws -> GeocodedPlace?

    /// 複数の住所から緯度経度を一括取得する
    func geocodeMultiple(addresses: [String]) async throws -> [GeocodedPlace]
}

final class GeocodingService: GeocodingServiceProtocol {
    private let geocoder = CLGeocoder()

    func geocode(address: String) async throws -> GeocodedPlace? {
        AppLogger.search.info("住所のジオコーディングを開始: \(address)")

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                AppLogger.search.warning("住所が見つかりませんでした: \(address)")
                return nil
            }

            let resolvedAddress = formatAddress(from: placemark)
            let result = GeocodedPlace(
                originalAddress: address,
                resolvedAddress: resolvedAddress,
                coordinate: location.coordinate
            )

            AppLogger.search.info(
                "ジオコーディング完了: \(address) -> (\(location.coordinate.latitude), \(location.coordinate.longitude))"
            )

            return result
        } catch {
            AppLogger.search.error("ジオコーディングに失敗しました: \(error.localizedDescription)")
            throw AppError.searchFailed(underlying: error)
        }
    }

    func geocodeMultiple(addresses: [String]) async throws -> [GeocodedPlace] {
        AppLogger.search.info("\(addresses.count)件の住所をジオコーディング開始")

        var results: [GeocodedPlace] = []
        var errors: [Error] = []

        // CLGeocoderはシリアル処理が推奨されるため、順次処理
        for address in addresses {
            do {
                if let place = try await geocode(address: address) {
                    results.append(place)
                }
                // レート制限を避けるための小さな遅延
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                errors.append(error)
                AppLogger.search.warning("住所のジオコーディングをスキップ: \(address)")
            }
        }

        if results.isEmpty && !errors.isEmpty {
            throw errors.first!
        }

        AppLogger.search.info("ジオコーディング完了: \(results.count)/\(addresses.count)件成功")
        return results
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        if let postalCode = placemark.postalCode {
            components.append("〒\(postalCode)")
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        if let name = placemark.name,
           !components.contains(name) {
            components.append(name)
        }

        return components.joined(separator: " ")
    }
}
