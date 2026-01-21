import CoreLocation
import Foundation
import MapKit
import Testing
@testable import handheld

// MARK: - PlanGeneratorService Tests

struct PlanGeneratorServiceTests {
    // MARK: - matchGeneratedSpotsWithPlaces Tests

    @Test func matchGeneratedSpotsWithPlaces_exactMatch_returnsMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京駅"),
            TestFactory.createMockPlace(name: "渋谷駅"),
            TestFactory.createMockPlace(name: "新宿駅")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京駅")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 1)
        #expect(result[0].place.name == "東京駅")
        #expect(result[0].spot.name == "東京駅")
    }

    @Test func matchGeneratedSpotsWithPlaces_normalizedMatch_returnsMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "Tokyo Station"),
            TestFactory.createMockPlace(name: "Shibuya")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "tokyo station")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 1)
        #expect(result[0].place.name == "Tokyo Station")
    }

    @Test func matchGeneratedSpotsWithPlaces_fuzzyMatch_returnsMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京スカイツリー"),
            TestFactory.createMockPlace(name: "渋谷駅")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京スカイツリ")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 1)
        #expect(result[0].place.name == "東京スカイツリー")
    }

    @Test func matchGeneratedSpotsWithPlaces_noMatch_returnsEmpty() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京駅"),
            TestFactory.createMockPlace(name: "渋谷駅")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "完全に異なる場所")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.isEmpty)
    }

    @Test func matchGeneratedSpotsWithPlaces_multipleSpots_allMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京駅"),
            TestFactory.createMockPlace(name: "渋谷駅"),
            TestFactory.createMockPlace(name: "新宿駅")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京駅"),
            TestFactory.createGeneratedSpotInfo(name: "渋谷駅"),
            TestFactory.createGeneratedSpotInfo(name: "新宿駅")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 3)
    }

    @Test func matchGeneratedSpotsWithPlaces_partialMatch_returnsSomeMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京駅"),
            TestFactory.createMockPlace(name: "渋谷駅")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京駅"),
            TestFactory.createGeneratedSpotInfo(name: "存在しない駅")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 1)
        #expect(result[0].place.name == "東京駅")
    }

    @Test func matchGeneratedSpotsWithPlaces_emptyGeneratedSpots_returnsEmpty() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京駅")
        ]
        let generatedSpots: [GeneratedSpotInfo] = []

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.isEmpty)
    }

    @Test func matchGeneratedSpotsWithPlaces_emptyCandidatePlaces_returnsEmpty() {
        let service = PlanGeneratorService()
        let candidatePlaces: [Place] = []
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京駅")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.isEmpty)
    }

    @Test func matchGeneratedSpotsWithPlaces_normalizedWithSymbols_returnsMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京（駅）")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京駅")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 1)
    }

    @Test func matchGeneratedSpotsWithPlaces_normalizedWithSpaces_returnsMatched() {
        let service = PlanGeneratorService()
        let candidatePlaces = [
            TestFactory.createMockPlace(name: "東京 駅")
        ]
        let generatedSpots = [
            TestFactory.createGeneratedSpotInfo(name: "東京駅")
        ]

        let result = service.matchGeneratedSpotsWithPlaces(
            generatedSpots: generatedSpots,
            candidatePlaces: candidatePlaces
        )

        #expect(result.count == 1)
    }
}

// MARK: - PlanGeneratorError Tests

struct PlanGeneratorErrorTests {
    @Test func aiUnavailable_hasCorrectDescription() {
        let error = PlanGeneratorError.aiUnavailable
        #expect(error.errorDescription == "Apple Intelligenceが利用できません")
    }

    @Test func noSpotsGenerated_hasCorrectDescription() {
        let error = PlanGeneratorError.noSpotsGenerated
        #expect(error.errorDescription == "スポットを生成できませんでした")
    }

    @Test func invalidResponse_hasCorrectDescription() {
        let error = PlanGeneratorError.invalidResponse
        #expect(error.errorDescription == "AIからの応答が不正です")
    }

    @Test func generationFailed_includesUnderlyingError() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "テストエラー"]
        )
        let error = PlanGeneratorError.generationFailed(underlying: underlyingError)
        #expect(error.errorDescription?.contains("テストエラー") == true)
    }
}
