import Foundation
import CoreLocation
import Observation
import os

/// 位置情報取得時のエラー。
enum LocationError: LocalizedError {
    /// 一時的に位置を特定できない（CLError.Code 0）。
    case locationUnknown
    /// 位置情報の権限が拒否されている（CLError.Code 1）。
    case denied
    /// ネットワークエラーが発生した（CLError.Code 2）。
    case network
    /// 方位の取得に失敗した（CLError.Code 3）。
    case headingFailure
    /// その他のエラー。
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .locationUnknown:
            return "現在地を特定できません。Wi-Fiをオンにして再試行してください"
        case .denied:
            return "位置情報へのアクセスが拒否されています"
        case .network:
            return "ネットワークエラーが発生しました"
        case .headingFailure:
            return "方位を取得できません"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    /// リトライ可能なエラーかどうか。
    var isRetryable: Bool {
        switch self {
        case .locationUnknown, .network:
            return true
        default:
            return false
        }
    }

    /// CoreLocationエラーからLocationErrorを生成する。
    ///
    /// - Parameter error: CoreLocationのエラー
    /// - Returns: 対応するLocationError
    static func from(_ error: Error) -> LocationError {
        let nsError = error as NSError
        guard nsError.domain == kCLErrorDomain else {
            return .unknown(error)
        }

        switch CLError.Code(rawValue: nsError.code) {
        case .locationUnknown:
            return .locationUnknown
        case .denied:
            return .denied
        case .network:
            return .network
        case .headingFailure:
            return .headingFailure
        default:
            return .unknown(error)
        }
    }
}

/// 位置情報を管理するクラス。
///
/// CLLocationManagerをラップし、位置情報の取得・権限管理を行います。
/// `@Observable`マクロを使用してSwiftUIビューとバインドします。
///
/// ## 概要
///
/// このクラスは以下の機能を提供します：
/// - 位置情報の権限リクエスト
/// - 現在地の取得（単発/継続）
/// - エラー時の自動リトライ
///
/// ## 使用例
///
/// ```swift
/// let locationManager = LocationManager()
/// locationManager.requestLocationPermission()
///
/// // 現在地を取得
/// locationManager.requestCurrentLocation()
/// let coordinate = locationManager.currentLocation
/// ```
///
/// - SeeAlso: ``LocationError``
@Observable
final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()

    /// 現在地の座標。
    var currentLocation: CLLocationCoordinate2D?
    /// 現在の権限ステータス。
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// 発生したエラー。
    var locationError: LocationError?
    /// 継続トラッキング中かどうか。
    var isTracking: Bool = false
    /// 水平精度（メートル）。
    var horizontalAccuracy: CLLocationAccuracy?

    private var retryCount: Int = 0
    private let maxRetryCount: Int = 3
    private let retryDelay: TimeInterval = 2.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// 継続的な位置情報トラッキングを開始する。
    func startContinuousTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            AppLogger.location.info("位置情報の権限がないためトラッキングを開始できません")
            requestLocationPermission()
            return
        }
        locationManager.distanceFilter = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        isTracking = true
        AppLogger.location.info("位置情報のトラッキングを開始しました")
    }

    /// 継続的な位置情報トラッキングを停止する。
    func stopContinuousTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        isTracking = false
        AppLogger.location.info("位置情報のトラッキングを停止しました")
    }

    /// 位置情報の使用許可をリクエストする。
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 現在地を単発で取得する。
    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        horizontalAccuracy = location.horizontalAccuracy
        locationError = nil
        retryCount = 0
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationErr = LocationError.from(error)
        locationError = locationErr
        AppLogger.location.error("位置情報の取得に失敗しました: \(locationErr.errorDescription ?? "不明なエラー")")

        if locationErr.isRetryable && retryCount < maxRetryCount {
            retryCount += 1
            AppLogger.location.info("位置情報の取得をリトライします (\(self.retryCount)/\(self.maxRetryCount))")
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                self?.locationManager.requestLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        AppLogger.location.info("位置情報の権限が変更されました: \(String(describing: manager.authorizationStatus))")
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            retryCount = 0
            locationError = nil
            locationManager.requestLocation()
        }
    }
}
