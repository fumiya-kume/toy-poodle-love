import Testing
import CoreLocation
@testable import handheld

struct AppErrorTests {
    // MARK: - Location Errors

    @Test func locationPermissionDeniedDescription() {
        let error = AppError.locationPermissionDenied
        #expect(error.errorDescription == "位置情報の使用が許可されていません")
    }

    @Test func locationPermissionRestrictedDescription() {
        let error = AppError.locationPermissionRestricted
        #expect(error.errorDescription == "位置情報の使用が制限されています")
    }

    @Test func locationUnavailableDescription() {
        let error = AppError.locationUnavailable
        #expect(error.errorDescription == "現在地を取得できません")
    }

    // MARK: - Search Errors

    @Test func searchFailedDescription() {
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)
        let error = AppError.searchFailed(underlying: underlyingError)
        #expect(error.errorDescription == "検索に失敗しました")
    }

    @Test func searchNoResultsDescription() {
        let error = AppError.searchNoResults
        #expect(error.errorDescription == "検索結果が見つかりませんでした")
    }

    // MARK: - Directions Errors

    @Test func routeCalculationFailedDescription() {
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)
        let error = AppError.routeCalculationFailed(underlying: underlyingError)
        #expect(error.errorDescription == "経路の計算に失敗しました")
    }

    @Test func noRouteFoundDescription() {
        let error = AppError.noRouteFound
        #expect(error.errorDescription == "経路が見つかりませんでした")
    }

    @Test func invalidCoordinatesDescription() {
        let error = AppError.invalidCoordinates
        #expect(error.errorDescription == "無効な座標です")
    }

    // MARK: - Look Around Errors

    @Test func lookAroundNotAvailableDescription() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let error = AppError.lookAroundNotAvailable(coordinate: coordinate)
        #expect(error.errorDescription == "この場所ではLook Aroundを利用できません")
    }

    @Test func lookAroundFetchFailedDescription() {
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)
        let error = AppError.lookAroundFetchFailed(underlying: underlyingError)
        #expect(error.errorDescription == "Look Aroundの取得に失敗しました")
    }

    // MARK: - LocalizedError Conformance

    @Test func conformsToLocalizedError() {
        let error: any LocalizedError = AppError.locationUnavailable
        #expect(error.errorDescription != nil)
    }
}
