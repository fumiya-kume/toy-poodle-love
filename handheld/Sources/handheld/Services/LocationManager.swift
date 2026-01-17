import Foundation
import CoreLocation
import Observation

enum LocationError: LocalizedError {
    case locationUnknown      // Code 0: 一時的に取得不可
    case denied               // Code 1: 権限拒否
    case network              // Code 2: ネットワークエラー
    case headingFailure       // Code 3: 方位取得失敗
    case unknown(Error)       // その他

    var errorDescription: String? {
        switch self {
        case .locationUnknown:
            return "現在地を特定できません。屋外で再試行してください"
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

    var isRetryable: Bool {
        switch self {
        case .locationUnknown, .network:
            return true
        default:
            return false
        }
    }

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

@Observable
final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()

    var currentLocation: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: LocationError?
    var isTracking: Bool = false

    private var retryCount: Int = 0
    private let maxRetryCount: Int = 3
    private let retryDelay: TimeInterval = 2.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startContinuousTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.distanceFilter = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        isTracking = true
    }

    func stopContinuousTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        isTracking = false
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

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
        locationError = nil
        retryCount = 0
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationErr = LocationError.from(error)
        locationError = locationErr

        if locationErr.isRetryable && retryCount < maxRetryCount {
            retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                self?.locationManager.requestLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            retryCount = 0
            locationError = nil
            locationManager.requestLocation()
        }
    }
}
