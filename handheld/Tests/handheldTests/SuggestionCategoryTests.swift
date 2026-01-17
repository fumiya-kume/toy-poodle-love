import SwiftUI
import Testing
@testable import handheld

struct SuggestionCategoryTests {
    // MARK: - rawValue

    @Test func station_rawValue_isCorrect() {
        #expect(SuggestionCategory.station.rawValue == "station")
    }

    @Test func searchQuery_rawValue_isCorrect() {
        #expect(SuggestionCategory.searchQuery.rawValue == "searchQuery")
    }

    @Test func poi_rawValue_isCorrect() {
        #expect(SuggestionCategory.poi.rawValue == "poi")
    }

    @Test func hotel_rawValue_isCorrect() {
        #expect(SuggestionCategory.hotel.rawValue == "hotel")
    }

    @Test func restaurant_rawValue_isCorrect() {
        #expect(SuggestionCategory.restaurant.rawValue == "restaurant")
    }

    @Test func hospital_rawValue_isCorrect() {
        #expect(SuggestionCategory.hospital.rawValue == "hospital")
    }

    @Test func park_rawValue_isCorrect() {
        #expect(SuggestionCategory.park.rawValue == "park")
    }

    @Test func shopping_rawValue_isCorrect() {
        #expect(SuggestionCategory.shopping.rawValue == "shopping")
    }

    @Test func generic_rawValue_isCorrect() {
        #expect(SuggestionCategory.generic.rawValue == "generic")
    }

    // MARK: - icon

    @Test func station_icon_isTram() {
        #expect(SuggestionCategory.station.icon == "tram.fill")
    }

    @Test func searchQuery_icon_isMagnifyingGlass() {
        #expect(SuggestionCategory.searchQuery.icon == "magnifyingglass")
    }

    @Test func poi_icon_isMappin() {
        #expect(SuggestionCategory.poi.icon == "mappin")
    }

    @Test func hotel_icon_isBed() {
        #expect(SuggestionCategory.hotel.icon == "bed.double.fill")
    }

    @Test func restaurant_icon_isForkKnife() {
        #expect(SuggestionCategory.restaurant.icon == "fork.knife")
    }

    @Test func hospital_icon_isCross() {
        #expect(SuggestionCategory.hospital.icon == "cross.fill")
    }

    @Test func park_icon_isLeaf() {
        #expect(SuggestionCategory.park.icon == "leaf.fill")
    }

    @Test func shopping_icon_isBag() {
        #expect(SuggestionCategory.shopping.icon == "bag.fill")
    }

    @Test func generic_icon_isMappin() {
        #expect(SuggestionCategory.generic.icon == "mappin")
    }

    // MARK: - backgroundColor

    @Test func station_backgroundColor_isGreen() {
        #expect(SuggestionCategory.station.backgroundColor == .green)
    }

    @Test func poi_backgroundColor_isOrange() {
        #expect(SuggestionCategory.poi.backgroundColor == .orange)
    }

    @Test func hotel_backgroundColor_isPurple() {
        #expect(SuggestionCategory.hotel.backgroundColor == .purple)
    }

    @Test func restaurant_backgroundColor_isOrange() {
        #expect(SuggestionCategory.restaurant.backgroundColor == .orange)
    }

    @Test func hospital_backgroundColor_isRed() {
        #expect(SuggestionCategory.hospital.backgroundColor == .red)
    }

    @Test func park_backgroundColor_isGreen() {
        #expect(SuggestionCategory.park.backgroundColor == .green)
    }

    @Test func shopping_backgroundColor_isBlue() {
        #expect(SuggestionCategory.shopping.backgroundColor == .blue)
    }

    // MARK: - CaseIterable

    @Test func allCases_containsNineCases() {
        #expect(SuggestionCategory.allCases.count == 9)
    }
}
