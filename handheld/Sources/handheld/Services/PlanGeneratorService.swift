import Foundation
import MapKit
import os

// MARK: - AI生成用構造体

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

// MARK: - 公開構造体

/// AI生成されたプランの情報。
struct GeneratedPlan {
    /// プランのタイトル。
    let title: String
    /// 生成されたスポットのリスト。
    let spots: [GeneratedSpotInfo]
}

/// AI生成されたスポットの情報。
struct GeneratedSpotInfo {
    /// スポット名。
    let name: String
    /// スポットの説明文。
    let description: String
    /// 推奨滞在時間（分）。
    let stayMinutes: Int
}

// MARK: - エラー

/// プラン生成時のエラー。
enum PlanGeneratorError: Error, LocalizedError {
    /// Apple Intelligenceが利用できない。
    case aiUnavailable
    /// 生成処理に失敗した。
    case generationFailed(underlying: Error)
    /// スポットが生成されなかった。
    case noSpotsGenerated
    /// AIからの応答が不正。
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

// MARK: - プロトコル

/// 観光プラン生成サービスのプロトコル。
///
/// AI（Apple Intelligence）を使用してテーマに基づいた観光プランを生成します。
///
/// ## 概要
///
/// このプロトコルは以下の機能を定義します：
/// 1. AI生成機能の利用可否確認
/// 2. テーマと候補地からのプラン生成
/// 3. 生成結果と候補地のマッチング
///
/// ## 使用例
///
/// ```swift
/// let service: PlanGeneratorServiceProtocol = PlanGeneratorService()
///
/// guard service.isAvailable else {
///     throw PlanGeneratorError.aiUnavailable
/// }
///
/// let plan = try await service.generatePlan(
///     theme: "歴史巡り",
///     categories: [.scenic],
///     candidatePlaces: candidatePlaces
/// )
/// ```
protocol PlanGeneratorServiceProtocol {
    /// Apple Intelligenceが利用可能かどうか。
    ///
    /// iOS 26.0以上かつデバイスがApple Intelligenceに対応している場合に`true`を返します。
    var isAvailable: Bool { get }

    /// テーマと候補地からプランを生成する。
    ///
    /// - Parameters:
    ///   - theme: プランのテーマ（例: "神社仏閣巡り"）
    ///   - categories: 選択されたカテゴリのリスト
    ///   - candidatePlaces: 候補となる場所のリスト
    ///
    /// - Returns: 生成されたプラン情報
    ///
    /// - Throws: ``PlanGeneratorError/aiUnavailable`` AIが利用不可の場合
    /// - Throws: ``PlanGeneratorError/noSpotsGenerated`` スポットが生成されなかった場合
    func generatePlan(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place]
    ) async throws -> GeneratedPlan

    /// 生成されたスポットを候補地とマッチングする。
    ///
    /// AI生成結果のスポット名と候補地リストを照合し、一致するペアを返します。
    /// 完全一致、正規化後の一致、ファジーマッチングの順で試行します。
    ///
    /// - Parameters:
    ///   - generatedSpots: AI生成されたスポット情報
    ///   - candidatePlaces: 候補地リスト
    ///
    /// - Returns: マッチングされたスポットと場所のペア配列
    func matchGeneratedSpotsWithPlaces(
        generatedSpots: [GeneratedSpotInfo],
        candidatePlaces: [Place]
    ) -> [(spot: GeneratedSpotInfo, place: Place)]
}

// MARK: - 実装

/// 観光プラン生成サービス。
///
/// ``PlanGeneratorServiceProtocol``の実装クラスです。
/// Apple IntelligenceのFoundationModelsフレームワークを使用してプランを生成します。
///
/// - Important: iOS 26.0以上が必要です。
/// - SeeAlso: ``PlanGeneratorServiceProtocol``, ``PlanGeneratorError``
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
        let similarityThreshold = 0.7  // 70%以上の類似度でマッチ

        for generatedSpot in generatedSpots {
            let normalizedSpotName = StringMatching.normalize(generatedSpot.name)

            // 1. 完全一致を試行
            if let matchedPlace = candidatePlaces.first(where: { $0.name == generatedSpot.name }) {
                matchedSpots.append((generatedSpot, matchedPlace))
                continue
            }

            // 2. 正規化後の完全一致を試行
            if let matchedPlace = candidatePlaces.first(where: {
                StringMatching.normalize($0.name) == normalizedSpotName
            }) {
                matchedSpots.append((generatedSpot, matchedPlace))
                continue
            }

            // 3. 類似度スコアでマッチング
            var bestMatch: (place: Place, score: Double)?
            for place in candidatePlaces {
                let score = StringMatching.similarityScore(
                    normalizedSpotName,
                    StringMatching.normalize(place.name)
                )
                if score >= similarityThreshold {
                    if bestMatch == nil || score > bestMatch!.score {
                        bestMatch = (place, score)
                    }
                }
            }

            if let match = bestMatch {
                AppLogger.ai.debug("ファジーマッチング: '\(generatedSpot.name)' → '\(match.place.name)' (score: \(String(format: "%.2f", match.score)))")
                matchedSpots.append((generatedSpot, match.place))
            } else {
                AppLogger.ai.warning("マッチング失敗: '\(generatedSpot.name)'")
            }
        }

        return matchedSpots
    }
}
