import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.handheld"

    static let location = Logger(subsystem: subsystem, category: "Location")
    static let search = Logger(subsystem: subsystem, category: "Search")
    static let directions = Logger(subsystem: subsystem, category: "Directions")
    static let lookAround = Logger(subsystem: subsystem, category: "LookAround")
    static let autoDrive = Logger(subsystem: subsystem, category: "AutoDrive")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    static let cache = Logger(subsystem: subsystem, category: "Cache")
}
