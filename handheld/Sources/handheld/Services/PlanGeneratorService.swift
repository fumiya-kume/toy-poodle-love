import Foundation
import MapKit
import os

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct GeneratedPlanResponse {
    @Guide(description: "プランのタイトル（10-30文字）")
    let title: String

    @Guide(description: "選択されたスポットのリスト（3-9件）", .count(3...9))
    let spots: [GeneratedSpot]
}

@available(iOS 26.0, *)
@Generable
struct GeneratedSpot {
    @Guide(description: "候補地リストから選んだスポット名（完全一致）")
    let name: String

    @Guide(description: "スポットの魅力を簡潔に説明（1-2文、50文字以内）")
    let description: String

    @Guide(description: "推奨滞在時間（分）", .range(15...180))
    let stayMinutes: Int
}
#endif

struct GeneratedPlan {
    let title: String
    let spots: [GeneratedSpotInfo]
}

struct GeneratedSpotInfo {
    let name: String
    let description: String
    let stayMinutes: Int
}

enum PlanGeneratorError: Error, LocalizedError {
    case aiUnavailable
    case generationFailed(underlying: Error)
    case noSpotsGenerated
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .aiUnavailable:
            return "Apple Intelligenceが利用できません"
        case .generationFailed(let error):
            return "プラン生成に失敗しました: \(error.localizedDescription)"
        case .noSpotsGenerated:
            return "スポットを生成できませんでした"
        case .invalidResponse:
            return "AIからの応答が不正です"
        }
    }
}

protocol PlanGeneratorServiceProtocol {
    var isAvailable: Bool { get }
    func generatePlan(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place]
    ) async throws -> GeneratedPlan
    func matchGeneratedSpotsWithPlaces(
        generatedSpots: [GeneratedSpotInfo],
        candidatePlaces: [Place]
    ) -> [(spot: GeneratedSpotInfo, place: Place)]
}

final class PlanGeneratorService: PlanGeneratorServiceProtocol {
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
        #else
        return false
        #endif
    }

    func generatePlan(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place]
    ) async throws -> GeneratedPlan {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.isAvailable else {
                throw PlanGeneratorError.aiUnavailable
            }

            AppLogger.ai.info("AIプラン生成を開始: テーマ=\(theme), 候補地数=\(candidatePlaces.count)")

            let candidateNames = candidatePlaces.map { $0.name }.joined(separator: "\n- ")
            let categoryNames = categories.map { $0.rawValue }.joined(separator: "、")

            let prompt = """
            あなたは日本の観光プランナーです。以下の条件で車での観光プランを作成してください。

            【テーマ】
            \(theme)

            【カテゴリ】
            \(categoryNames)

            【候補地リスト】
            - \(candidateNames)

            【指示】
            1. 候補地リストから3〜9箇所を選んでください
            2. 地理的に効率的な順序（移動距離が短くなるよう）で並べてください
            3. 各スポットについて、テーマに沿った魅力を1-2文で説明してください
            4. 各スポットの推奨滞在時間を15〜180分の範囲で設定してください
            5. スポット名は候補地リストと完全に一致させてください
            6. プランのタイトルはテーマを反映した魅力的なものにしてください
            """

            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt, generating: GeneratedPlanResponse.self)
                let content = response.content

                guard !content.spots.isEmpty else {
                    throw PlanGeneratorError.noSpotsGenerated
                }

                let generatedPlan = GeneratedPlan(
                    title: content.title,
                    spots: content.spots.map { spot in
                        GeneratedSpotInfo(
                            name: spot.name,
                            description: spot.description,
                            stayMinutes: spot.stayMinutes
                        )
                    }
                )

                AppLogger.ai.info("AIプラン生成完了: タイトル=\(generatedPlan.title), スポット数=\(generatedPlan.spots.count)")
                return generatedPlan
            } catch let error as PlanGeneratorError {
                throw error
            } catch {
                AppLogger.ai.error("AIプラン生成に失敗: \(error.localizedDescription)")
                throw PlanGeneratorError.generationFailed(underlying: error)
            }
        } else {
            throw PlanGeneratorError.aiUnavailable
        }
        #else
        throw PlanGeneratorError.aiUnavailable
        #endif
    }

    func matchGeneratedSpotsWithPlaces(
        generatedSpots: [GeneratedSpotInfo],
        candidatePlaces: [Place]
    ) -> [(spot: GeneratedSpotInfo, place: Place)] {
        var matchedSpots: [(spot: GeneratedSpotInfo, place: Place)] = []

        for generatedSpot in generatedSpots {
            if let matchedPlace = candidatePlaces.first(where: { $0.name == generatedSpot.name }) {
                matchedSpots.append((generatedSpot, matchedPlace))
            } else if let matchedPlace = candidatePlaces.first(where: { $0.name.contains(generatedSpot.name) || generatedSpot.name.contains($0.name) }) {
                matchedSpots.append((generatedSpot, matchedPlace))
            }
        }

        return matchedSpots
    }
}
