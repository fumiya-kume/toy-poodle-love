import CoreLocation
import Foundation
import MapKit
import Testing
@testable import handheld

// MARK: - Route Formatting Tests

struct RouteFormattingTests {
    // MARK: - formattedDistance Tests

    @Test func formattedDistance_under1km_showsMeters() {
        let route = TestFactory.createMockRoute(distance: 500)
        #expect(route.formattedDistance == "500 m")
    }

    @Test func formattedDistance_exactly1km_showsKilometers() {
        let route = TestFactory.createMockRoute(distance: 1000)
        #expect(route.formattedDistance == "1.0 km")
    }

    @Test func formattedDistance_over1km_showsKilometers() {
        let route = TestFactory.createMockRoute(distance: 2500)
        #expect(route.formattedDistance == "2.5 km")
    }

    @Test func formattedDistance_largeDistance_showsKilometers() {
        let route = TestFactory.createMockRoute(distance: 12345)
        #expect(route.formattedDistance == "12.3 km")
    }

    @Test func formattedDistance_zeroMeters_showsZeroMeters() {
        let route = TestFactory.createMockRoute(distance: 0)
        #expect(route.formattedDistance == "0 m")
    }

    @Test func formattedDistance_999meters_showsMeters() {
        let route = TestFactory.createMockRoute(distance: 999)
        #expect(route.formattedDistance == "999 m")
    }

    @Test func formattedDistance_1001meters_showsKilometers() {
        let route = TestFactory.createMockRoute(distance: 1001)
        #expect(route.formattedDistance == "1.0 km")
    }

    // MARK: - formattedTravelTime Tests

    @Test func formattedTravelTime_under60min_showsMinutesOnly() {
        let route = TestFactory.createMockRoute(travelTime: 30 * 60) // 30 minutes
        #expect(route.formattedTravelTime == "30分")
    }

    @Test func formattedTravelTime_exactly60min_showsHoursAndMinutes() {
        let route = TestFactory.createMockRoute(travelTime: 60 * 60) // 60 minutes
        #expect(route.formattedTravelTime == "1時間0分")
    }

    @Test func formattedTravelTime_over60min_showsHoursAndMinutes() {
        let route = TestFactory.createMockRoute(travelTime: 90 * 60) // 90 minutes
        #expect(route.formattedTravelTime == "1時間30分")
    }

    @Test func formattedTravelTime_2hours_showsHoursAndMinutes() {
        let route = TestFactory.createMockRoute(travelTime: 120 * 60) // 120 minutes
        #expect(route.formattedTravelTime == "2時間0分")
    }

    @Test func formattedTravelTime_2hoursAnd15min_showsHoursAndMinutes() {
        let route = TestFactory.createMockRoute(travelTime: 135 * 60) // 135 minutes
        #expect(route.formattedTravelTime == "2時間15分")
    }

    @Test func formattedTravelTime_zeroMinutes_showsZeroMinutes() {
        let route = TestFactory.createMockRoute(travelTime: 0)
        #expect(route.formattedTravelTime == "0分")
    }

    @Test func formattedTravelTime_59minutes_showsMinutesOnly() {
        let route = TestFactory.createMockRoute(travelTime: 59 * 60) // 59 minutes
        #expect(route.formattedTravelTime == "59分")
    }

    @Test func formattedTravelTime_61minutes_showsHoursAndMinutes() {
        let route = TestFactory.createMockRoute(travelTime: 61 * 60) // 61 minutes
        #expect(route.formattedTravelTime == "1時間1分")
    }
}
