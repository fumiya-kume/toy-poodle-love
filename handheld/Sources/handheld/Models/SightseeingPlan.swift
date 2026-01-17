import Foundation
import SwiftData
import MapKit

@Model
final class SightseeingPlan {
    var id: UUID
    var title: String
    var theme: String
    var categoriesRawValue: String
    var startTime: Date?
    var createdAt: Date
    var updatedAt: Date
    var totalDuration: TimeInterval
    var totalDistance: Double
    var searchRadiusRawValue: Int
    var centerLatitude: Double
    var centerLongitude: Double

    @Relationship(deleteRule: .cascade, inverse: \PlanSpot.plan)
    var spots: [PlanSpot]

    var categories: [PlanCategory] {
        get {
            categoriesRawValue.split(separator: ",").compactMap { PlanCategory(rawValue: String($0)) }
        }
        set {
            categoriesRawValue = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }

    var searchRadius: SearchRadius {
        get {
            SearchRadius(rawValue: searchRadiusRawValue) ?? .large
        }
        set {
            searchRadiusRawValue = newValue.rawValue
        }
    }

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    var sortedSpots: [PlanSpot] {
        spots.sorted { $0.order < $1.order }
    }

    var formattedTotalDuration: String {
        let minutes = Int(totalDuration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)時間\(remainingMinutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(minutes)分"
        }
    }

    var formattedTotalDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1fkm", totalDistance / 1000)
        } else {
            return "\(Int(totalDistance))m"
        }
    }

    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }

    init(
        title: String,
        theme: String,
        categories: [PlanCategory],
        searchRadius: SearchRadius,
        centerCoordinate: CLLocationCoordinate2D,
        startTime: Date? = nil,
        spots: [PlanSpot] = []
    ) {
        self.id = UUID()
        self.title = title
        self.theme = theme
        self.categoriesRawValue = categories.map { $0.rawValue }.joined(separator: ",")
        self.searchRadiusRawValue = searchRadius.rawValue
        self.centerLatitude = centerCoordinate.latitude
        self.centerLongitude = centerCoordinate.longitude
        self.startTime = startTime
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalDuration = 0
        self.totalDistance = 0
        self.spots = spots
    }

    func calculateScheduledTime(for spot: PlanSpot) -> Date? {
        guard let startTime = startTime else { return nil }

        let sortedSpots = self.sortedSpots
        guard let index = sortedSpots.firstIndex(where: { $0.id == spot.id }) else { return nil }

        var currentTime = startTime

        for i in 0..<index {
            let previousSpot = sortedSpots[i]
            currentTime = currentTime.addingTimeInterval(previousSpot.estimatedStayDuration)
            if let travelTime = sortedSpots[i + 1].routeTravelTimeFromPrevious {
                currentTime = currentTime.addingTimeInterval(travelTime)
            }
        }

        return currentTime
    }

    func formattedScheduledTime(for spot: PlanSpot) -> String? {
        guard let scheduledTime = calculateScheduledTime(for: spot) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledTime)
    }
}
