import Foundation
import CoreLocation

/// アプリ全体で使用されるエラー型。
///
/// 位置情報、検索、ルート計算、Look Aroundに関連するエラーを定義します。
/// `LocalizedError`に準拠しており、ユーザー向けのエラーメッセージを提供します。
///
/// ## 使用例
///
/// ```swift
/// do {
///     let route = try await calculateRoute()
/// } catch let error as AppError {
///     showAlert(message: error.errorDescription ?? "不明なエラー")
/// }
/// ```
enum AppError: LocalizedError {
    // MARK: - 位置情報エラー

    /// 位置情報の使用が許可されていない。
    case locationPermissionDenied
    /// 位置情報の使用が制限されている。
    case locationPermissionRestricted
    /// 現在地を取得できない。
    case locationUnavailable

    // MARK: - 検索エラー

    /// 検索に失敗した。
    case searchFailed(underlying: Error)
    /// 検索結果が見つからなかった。
    case searchNoResults

    // MARK: - ルートエラー

    /// 経路計算に失敗した。
    case routeCalculationFailed(underlying: Error)
    /// 経路が見つからなかった。
    case noRouteFound
    /// 無効な座標が指定された。
    case invalidCoordinates

    // MARK: - Look Aroundエラー

    /// 指定座標でLook Aroundが利用できない。
    case lookAroundNotAvailable(coordinate: CLLocationCoordinate2D)
    /// Look Aroundの取得に失敗した。
    case lookAroundFetchFailed(underlying: Error)

    /// 関連するエラー（存在する場合）。
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

    /// 関連する座標（`lookAroundNotAvailable`の場合）。
    var associatedCoordinate: CLLocationCoordinate2D? {
        switch self {
        case .lookAroundNotAvailable(let coordinate):
            return coordinate
        default:
            return nil
        }
    }

    /// ユーザー向けのエラーメッセージ。
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
