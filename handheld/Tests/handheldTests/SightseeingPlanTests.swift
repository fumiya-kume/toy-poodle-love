import CoreLocation
import Testing
@testable import handheld

struct SightseeingPlanTests {
    // MARK: - Initialization

    @Test func init_setsCorrectValues() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テストプラン",
            theme: "歴史散策",
            categories: [.scenic, .activity],
            searchRadius: .medium,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        #expect(plan.title == "テストプラン")
        #expect(plan.theme == "歴史散策")
        #expect(plan.searchRadius == .medium)
        #expect(plan.centerLatitude == 35.6812)
        #expect(plan.centerLongitude == 139.7671)
        #expect(plan.totalDuration == 0)
        #expect(plan.totalDistance == 0)
        #expect(plan.spots.isEmpty)
    }

    // MARK: - categories

    @Test func categories_getterReturnsCorrectCategories() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [.scenic, .shopping],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        let categories = plan.categories
        #expect(categories.count == 2)
        #expect(categories.contains(.scenic))
        #expect(categories.contains(.shopping))
    }

    @Test func categories_setterUpdatesRawValue() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [.scenic],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        plan.categories = [.activity, .shopping]

        #expect(plan.categories.count == 2)
        #expect(plan.categories.contains(.activity))
        #expect(plan.categories.contains(.shopping))
    }

    // MARK: - searchRadius

    @Test func searchRadius_getterReturnsCorrectValue() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .small,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        #expect(plan.searchRadius == .small)
    }

    @Test func searchRadius_setterUpdatesRawValue() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        plan.searchRadius = .medium

        #expect(plan.searchRadius == .medium)
    }

    // MARK: - centerCoordinate

    @Test func centerCoordinate_returnsCorrectValue() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        let center = plan.centerCoordinate
        #expect(center.latitude == 35.6812)
        #expect(center.longitude == 139.7671)
    }

    // MARK: - formattedTotalDuration

    @Test func formattedTotalDuration_under60min_showsMinutes() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )
        plan.totalDuration = 30 * 60 // 30 minutes

        #expect(plan.formattedTotalDuration == "30分")
    }

    @Test func formattedTotalDuration_exactly60min_showsHours() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )
        plan.totalDuration = 60 * 60 // 60 minutes

        #expect(plan.formattedTotalDuration == "1時間")
    }

    @Test func formattedTotalDuration_over60min_showsHoursAndMinutes() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )
        plan.totalDuration = 90 * 60 // 90 minutes

        #expect(plan.formattedTotalDuration == "1時間30分")
    }

    // MARK: - formattedTotalDistance

    @Test func formattedTotalDistance_under1km_showsMeters() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )
        plan.totalDistance = 500

        #expect(plan.formattedTotalDistance == "500m")
    }

    @Test func formattedTotalDistance_over1km_showsKilometers() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )
        plan.totalDistance = 2500

        #expect(plan.formattedTotalDistance == "2.5km")
    }

    // MARK: - sortedSpots

    @Test func sortedSpots_returnsSortedByOrder() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let plan = SightseeingPlan(
            title: "テスト",
            theme: "テーマ",
            categories: [],
            searchRadius: .large,
            centerCoordinate: coordinate,
            startTime: nil,
            spots: []
        )

        let spot1 = TestFactory.createMockPlanSpot(order: 2, name: "Spot 2")
        let spot2 = TestFactory.createMockPlanSpot(order: 0, name: "Spot 0")
        let spot3 = TestFactory.createMockPlanSpot(order: 1, name: "Spot 1")
        plan.spots = [spot1, spot2, spot3]

        let sorted = plan.sortedSpots
        #expect(sorted[0].order == 0)
        #expect(sorted[1].order == 1)
        #expect(sorted[2].order == 2)
    }
}
