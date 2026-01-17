import Foundation
import CoreLocation

enum AppError: LocalizedError {
    // Location
    case locationPermissionDenied
    case locationPermissionRestricted
    case locationUnavailable

    // Search
    case searchFailed(underlying: Error)
    case searchNoResults

    // Directions
    case routeCalculationFailed(underlying: Error)
    case noRouteFound
    case invalidCoordinates

    // Look Around
    case lookAroundNotAvailable(coordinate: CLLocationCoordinate2D)
    case lookAroundFetchFailed(underlying: Error)

    var underlyingError: Error? {
        switch self {
        case .searchFailed(let underlying),
             .routeCalculationFailed(let underlying),
             .lookAroundFetchFailed(let underlying):
            return underlying
        default:
            return nil
        }
    }

    var associatedCoordinate: CLLocationCoordinate2D? {
        switch self {
        case .lookAroundNotAvailable(let coordinate):
            return coordinate
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .locationPermissionDenied:
            return "位置情報の使用が許可されていません"
        case .locationPermissionRestricted:
            return "位置情報の使用が制限されています"
        case .locationUnavailable:
            return "現在地を取得できません"
        case .searchFailed:
            return "検索に失敗しました"
        case .searchNoResults:
            return "検索結果が見つかりませんでした"
        case .routeCalculationFailed:
            return "経路の計算に失敗しました"
        case .noRouteFound:
            return "経路が見つかりませんでした"
        case .invalidCoordinates:
            return "無効な座標です"
        case .lookAroundNotAvailable:
            return "この場所ではLook Aroundを利用できません"
        case .lookAroundFetchFailed:
            return "Look Aroundの取得に失敗しました"
        }
    }
}
