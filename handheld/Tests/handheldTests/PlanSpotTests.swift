import CoreLocation
import Testing
@testable import handheld

struct PlanSpotTests {
    // MARK: - formattedStayDuration

    @Test func formattedStayDuration_under60min_showsMinutes() {
        let spot = TestFactory.createMockPlanSpot(stayDuration: 30 * 60) // 30 minutes
        #expect(spot.formattedStayDuration == "30分")
    }

    @Test func formattedStayDuration_exactly60min_showsHours() {
        let spot = TestFactory.createMockPlanSpot(stayDuration: 60 * 60) // 60 minutes
        #expect(spot.formattedStayDuration == "1時間")
    }

    @Test func formattedStayDuration_over60min_showsHoursAndMinutes() {
        let spot = TestFactory.createMockPlanSpot(stayDuration: 90 * 60) // 90 minutes
        #expect(spot.formattedStayDuration == "1時間30分")
    }

    @Test func formattedStayDuration_2hours_showsHours() {
        let spot = TestFactory.createMockPlanSpot(stayDuration: 120 * 60) // 120 minutes
        #expect(spot.formattedStayDuration == "2時間")
    }

    @Test func formattedStayDuration_2hoursAnd15min_showsHoursAndMinutes() {
        let spot = TestFactory.createMockPlanSpot(stayDuration: 135 * 60) // 135 minutes
        #expect(spot.formattedStayDuration == "2時間15分")
    }

    // MARK: - formattedTravelTimeFromPrevious

    @Test func formattedTravelTimeFromPrevious_nil_returnsNil() {
        let spot = TestFactory.createMockPlanSpot(routeTravelTimeFromPrevious: nil)
        #expect(spot.formattedTravelTimeFromPrevious == nil)
    }

    @Test func formattedTravelTimeFromPrevious_under60min_showsMinutes() {
        let spot = TestFactory.createMockPlanSpot(routeTravelTimeFromPrevious: 15 * 60) // 15 minutes
        #expect(spot.formattedTravelTimeFromPrevious == "15分")
    }

    @Test func formattedTravelTimeFromPrevious_exactly60min_showsHours() {
        let spot = TestFactory.createMockPlanSpot(routeTravelTimeFromPrevious: 60 * 60) // 60 minutes
        #expect(spot.formattedTravelTimeFromPrevious == "1時間")
    }

    @Test func formattedTravelTimeFromPrevious_over60min_showsHoursAndMinutes() {
        let spot = TestFactory.createMockPlanSpot(routeTravelTimeFromPrevious: 75 * 60) // 75 minutes
        #expect(spot.formattedTravelTimeFromPrevious == "1時間15分")
    }

    // MARK: - formattedDistanceFromPrevious

    @Test func formattedDistanceFromPrevious_nil_returnsNil() {
        let spot = TestFactory.createMockPlanSpot(routeDistanceFromPrevious: nil)
        #expect(spot.formattedDistanceFromPrevious == nil)
    }

    @Test func formattedDistanceFromPrevious_under1km_showsMeters() {
        let spot = TestFactory.createMockPlanSpot(routeDistanceFromPrevious: 500)
        #expect(spot.formattedDistanceFromPrevious == "500m")
    }

    @Test func formattedDistanceFromPrevious_exactly1km_showsKilometers() {
        let spot = TestFactory.createMockPlanSpot(routeDistanceFromPrevious: 1000)
        #expect(spot.formattedDistanceFromPrevious == "1.0km")
    }

    @Test func formattedDistanceFromPrevious_over1km_showsKilometers() {
        let spot = TestFactory.createMockPlanSpot(routeDistanceFromPrevious: 2500)
        #expect(spot.formattedDistanceFromPrevious == "2.5km")
    }

    @Test func formattedDistanceFromPrevious_decimalKilometers_showsOneDecimal() {
        let spot = TestFactory.createMockPlanSpot(routeDistanceFromPrevious: 1234)
        #expect(spot.formattedDistanceFromPrevious == "1.2km")
    }

    // MARK: - coordinate

    @Test func coordinate_returnsCorrectCLLocationCoordinate2D() {
        let spot = TestFactory.createMockPlanSpot(latitude: 35.6812, longitude: 139.7671)
        let coordinate = spot.coordinate
        #expect(coordinate.latitude == 35.6812)
        #expect(coordinate.longitude == 139.7671)
    }

    // MARK: - Initialization

    @Test func init_setsCorrectValues() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let spot = PlanSpot(
            order: 1,
            name: "テストスポット",
            address: "東京都千代田区",
            coordinate: coordinate,
            aiDescription: "テスト説明",
            estimatedStayDuration: 30 * 60,
            isFavorite: true
        )

        #expect(spot.order == 1)
        #expect(spot.name == "テストスポット")
        #expect(spot.address == "東京都千代田区")
        #expect(spot.latitude == 35.6812)
        #expect(spot.longitude == 139.7671)
        #expect(spot.aiDescription == "テスト説明")
        #expect(spot.estimatedStayDuration == 30 * 60)
        #expect(spot.isFavorite == true)
        #expect(spot.routeDistanceFromPrevious == nil)
        #expect(spot.routeTravelTimeFromPrevious == nil)
    }

    @Test func init_defaultIsFavoriteIsFalse() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let spot = PlanSpot(
            order: 0,
            name: "Test",
            address: "Address",
            coordinate: coordinate,
            aiDescription: "Description",
            estimatedStayDuration: 30 * 60
        )

        #expect(spot.isFavorite == false)
    }
}
