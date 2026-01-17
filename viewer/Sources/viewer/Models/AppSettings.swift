import Foundation

struct AppSettings: Codable, Equatable {
    var autoPlayOnLaunch: Bool = false
    var showControlsOnHover: Bool = true
    var controlHideDelay: Double = 3.0
    var rememberWindowPositions: Bool = true

    static let `default` = AppSettings()
}
