import Foundation

enum SearchRadius: Int, Codable, CaseIterable, Identifiable {
    case small = 3000   // 3km
    case medium = 5000  // 5km
    case large = 10000  // 10km

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .small: return "3km"
        case .medium: return "5km"
        case .large: return "10km"
        }
    }

    var meters: Double {
        Double(rawValue)
    }
}
