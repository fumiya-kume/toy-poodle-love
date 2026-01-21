import Foundation
import MapKit
import os

// MARK: - Web API型定義

// MARK: Route Generate API (/api/route/generate)

/// ルート生成APIリクエスト
fileprivate struct RouteGenerateRequest: Codable {
    let input: RouteGenerateInput
}

/// ルート生成入力パラメータ
fileprivate struct RouteGenerateInput: Codable {
    let startPoint: String
    let purpose: String
    let spotCount: Int
    let model: String
    let language: String?
}

/// ルート生成APIレスポンス
fileprivate struct RouteGenerateResponse: Decodable {
    let success: Bool
    let data: RouteGenerateData?
    let error: String?
}

/// ルート生成データ
fileprivate struct RouteGenerateData: Decodable {
    let generatedAt: String
    let routeName: String
    let spots: [RouteGenerateSpot]
    let model: String
    let processingTimeMs: Int
}

/// ルート生成スポット
fileprivate struct RouteGenerateSpot: Decodable {
    let name: String
    let type: String
    let description: String?
    let generatedNote: String?
}

// MARK: Pipeline API (deprecated)

/// Web API パイプラインリクエスト
fileprivate struct PipelineRequest: Codable {
    let startPoint: String
    let purpose: String
    let spotCount: Int
    let model: String
}

/// Web API パイプラインレスポンス
fileprivate struct PipelineResponse: Decodable {
    let success: Bool
    let request: PipelineRequest
    let routeGeneration: RouteGenerationStepResult
    let geocoding: GeocodingStepResult
    let routeOptimization: RouteOptimizationStepResult
    let totalProcessingTimeMs: Int
    let error: String?
}

/// パイプラインの各ステップの状態
fileprivate enum PipelineStepStatus: String, Decodable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
}

/// AIルート生成ステップの結果
fileprivate struct RouteGenerationStepResult: Decodable {
    let status: PipelineStepStatus
    let routeName: String?
    let spots: [GeneratedRouteSpot]?
    let processingTimeMs: Int?
    let error: String?
}

/// ジオコーディングステップの結果
fileprivate struct GeocodingStepResult: Decodable {
    let status: PipelineStepStatus
    let places: [GeocodedPlace]?
    let failedSpots: [String]?
    let processingTimeMs: Int?
    let error: String?
}

/// ルート最適化ステップの結果
fileprivate struct RouteOptimizationStepResult: Decodable {
    let status: PipelineStepStatus
    let orderedWaypoints: [OptimizedWaypoint]?
    let legs: [RouteLeg]?
    let totalDistanceMeters: Double?
    let totalDurationSeconds: Double?
    let processingTimeMs: Int?
    let error: String?
}

/// 生成されたルートの地点
fileprivate struct GeneratedRouteSpot: Decodable {
    let name: String
    let type: String
    let description: String?
    let point: String?
}

/// ジオコーディング結果
fileprivate struct GeocodedPlace: Decodable {
    let inputAddress: String
    let spotName: String?
    let formattedAddress: String
    let location: LatLng
    let placeId: String
}

/// 緯度経度の座標
fileprivate struct LatLng: Decodable {
    let latitude: Double
    let longitude: Double
}

/// 最適化されたルートの地点情報
fileprivate struct OptimizedWaypoint: Decodable {
    let originalIndex: Int
    let optimizedOrder: Int
    let waypoint: RouteWaypoint
}

/// ルート最適化の入力地点
fileprivate struct RouteWaypoint: Decodable {
    let name: String?
    let placeId: String?
}

/// ルート区間の情報
fileprivate struct RouteLeg: Decodable {
    let fromIndex: Int
    let toIndex: Int
    let distanceMeters: Double
    let durationSeconds: Double
}

// MARK: - Web APIクライアント

/// Web API通信クライアント
fileprivate actor WebAPIClient {
    private let baseURL: URL

    enum WebAPIError: Error, LocalizedError {
        case networkError(underlying: Error)
        case invalidResponse
        case httpError(statusCode: Int, message: String?)
        case apiError(message: String)
        case decodingError(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .networkError(let error):
                return "ネットワークエラー: \(error.localizedDescription)"
            case .invalidResponse:
                return "サーバーからの応答が不正です"
            case .httpError(let statusCode, let message):
                return "HTTPエラー (\(statusCode)): \(message ?? "不明なエラー")"
            case .apiError(let message):
                return "APIエラー: \(message)"
            case .decodingError(let error):
                return "レスポンスの解析に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    init(baseURL: URL = URL(string: "https://toy-poodle-lover.vercel.app")!) {
        self.baseURL = baseURL
    }

    func generatePlan(request: PipelineRequest) async throws -> PipelineResponse {
        let endpoint = baseURL.appendingPathComponent("api/pipeline/route-optimize")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            AppLogger.ai.error("リクエストのエンコードに失敗: \(error.localizedDescription)")
            throw WebAPIError.networkError(underlying: error)
        }

        AppLogger.ai.info("Web API リクエスト送信: \(endpoint.absoluteString)")
        AppLogger.ai.debug("リクエストパラメータ: startPoint=\(request.startPoint), purpose=\(request.purpose), spotCount=\(request.spotCount), model=\(request.model)")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            AppLogger.ai.error("ネットワークエラー: \(error.localizedDescription)")
            throw WebAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.ai.error("HTTPレスポンスが取得できません")
            throw WebAPIError.invalidResponse
        }

        AppLogger.ai.debug("HTTPステータスコード: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            AppLogger.ai.error("HTTPエラー: \(httpResponse.statusCode), メッセージ: \(errorMessage ?? "なし")")
            throw WebAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        let pipelineResponse: PipelineResponse

        do {
            pipelineResponse = try decoder.decode(PipelineResponse.self, from: data)
        } catch {
            AppLogger.ai.error("レスポンスのデコードに失敗: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLogger.ai.debug("レスポンスJSON: \(jsonString)")
            }
            throw WebAPIError.decodingError(underlying: error)
        }

        guard pipelineResponse.success else {
            let errorMessage = pipelineResponse.error ?? "不明なエラー"
            AppLogger.ai.error("APIエラー: \(errorMessage)")
            throw WebAPIError.apiError(message: errorMessage)
        }

        AppLogger.ai.info("Web API レスポンス受信成功: 処理時間=\(pipelineResponse.totalProcessingTimeMs)ms")

        return pipelineResponse
    }

    /// ルート生成APIを呼び出す
    ///
    /// POST /api/route/generate エンドポイントを呼び出します。
    ///
    /// - Parameter request: ルート生成リクエスト
    /// - Returns: ルート生成レスポンス
    /// - Throws: ``WebAPIError`` ネットワークエラーまたはAPIエラー
    func generateRoute(request: RouteGenerateRequest) async throws -> RouteGenerateResponse {
        let endpoint = baseURL.appendingPathComponent("api/route/generate")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            AppLogger.ai.error("リクエストのエンコードに失敗: \(error.localizedDescription)")
            throw WebAPIError.networkError(underlying: error)
        }

        AppLogger.ai.info("Web API リクエスト送信: \(endpoint.absoluteString)")
        AppLogger.ai.debug("リクエストパラメータ: startPoint=\(request.input.startPoint), purpose=\(request.input.purpose), spotCount=\(request.input.spotCount), model=\(request.input.model)")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            AppLogger.ai.error("ネットワークエラー: \(error.localizedDescription)")
            throw WebAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.ai.error("HTTPレスポンスが取得できません")
            throw WebAPIError.invalidResponse
        }

        AppLogger.ai.debug("HTTPステータスコード: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            AppLogger.ai.error("HTTPエラー: \(httpResponse.statusCode), メッセージ: \(errorMessage ?? "なし")")
            throw WebAPIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        let routeResponse: RouteGenerateResponse

        do {
            routeResponse = try decoder.decode(RouteGenerateResponse.self, from: data)
        } catch {
            AppLogger.ai.error("レスポンスのデコードに失敗: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLogger.ai.debug("レスポンスJSON: \(jsonString)")
            }
            throw WebAPIError.decodingError(underlying: error)
        }

        guard routeResponse.success, let data = routeResponse.data else {
            let errorMessage = routeResponse.error ?? "不明なエラー"
            AppLogger.ai.error("APIエラー: \(errorMessage)")
            throw WebAPIError.apiError(message: errorMessage)
        }

        AppLogger.ai.info("Web API レスポンス受信成功: 処理時間=\(data.processingTimeMs)ms")

        return routeResponse
    }
}

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

    /// Web APIを使用したかどうか。
    ///
    /// 最後の`generatePlan`呼び出しでWeb APIを使用した場合に`true`を返します。
    var usedWebAPI: Bool { get }

    /// テーマと候補地からプランを生成する。
    ///
    /// - Parameters:
    ///   - theme: プランのテーマ（例: "神社仏閣巡り"）
    ///   - categories: 選択されたカテゴリのリスト
    ///   - candidatePlaces: 候補となる場所のリスト
    ///   - startPoint: 開始地点のPlaceオブジェクト（Foundation Models用）
    ///   - startPointName: 開始地点の名前文字列（Web API用、オプション）
    ///
    /// - Returns: 生成されたプラン情報
    ///
    /// - Throws: ``PlanGeneratorError/aiUnavailable`` AIが利用不可の場合
    /// - Throws: ``PlanGeneratorError/noSpotsGenerated`` スポットが生成されなかった場合
    func generatePlan(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place],
        startPoint: Place,
        startPointName: String?
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

    /// Web APIのジオコーディング結果からPlaceオブジェクトを生成する。
    ///
    /// `generatePlan`メソッドでWeb APIを使用した場合に、
    /// ジオコーディング結果から直接`Place`オブジェクトを作成します。
    ///
    /// - Parameter generatedSpots: AI生成されたスポット情報
    /// - Returns: Web APIの座標情報を使用した`Place`オブジェクトの配列
    func getPlacesFromWebAPIResult(generatedSpots: [GeneratedSpotInfo]) -> [Place]
}

// MARK: - 実装

/// 観光プラン生成サービス。
///
/// ``PlanGeneratorServiceProtocol``の実装クラスです。
/// Apple IntelligenceのFoundationModelsフレームワークを使用してプランを生成します。
/// Foundation Modelsが利用できない場合は、Web APIにフォールバックします。
///
/// - Important: iOS 26.0以上が必要です（Foundation Models使用時）。
/// - SeeAlso: ``PlanGeneratorServiceProtocol``, ``PlanGeneratorError``
final class PlanGeneratorService: PlanGeneratorServiceProtocol {
    /// Web APIクライアント
    private let webAPIClient = WebAPIClient()

    /// 最後のWeb APIジオコーディング結果（キャッシュ）
    private var lastWebAPIGeocodingPlaces: [GeocodedPlace]?

    /// Web APIを使用したかどうか
    var usedWebAPI: Bool {
        lastWebAPIGeocodingPlaces != nil
    }

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
        candidatePlaces: [Place],
        startPoint: Place,
        startPointName: String? = nil
    ) async throws -> GeneratedPlan {
        // 1. Foundation Modelsを試行
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAvailable {
            AppLogger.ai.info("AIプラン生成を開始（Foundation Models使用）: テーマ=\(theme), 候補地数=\(candidatePlaces.count)")

            do {
                return try await generateWithFoundationModels(
                    theme: theme,
                    categories: categories,
                    candidatePlaces: candidatePlaces,
                    startPoint: startPoint
                )
            } catch {
                AppLogger.ai.warning("Foundation Models失敗、Web APIにフォールバック: \(error.localizedDescription)")
            }
        }
        #endif

        // 2. Web APIにフォールバック
        AppLogger.ai.info("Web APIを使用してプラン生成を開始: テーマ=\(theme), 候補地数=\(candidatePlaces.count)")
        return try await generateWithWebAPI(
            theme: theme,
            categories: categories,
            candidatePlaces: candidatePlaces,
            startPoint: startPoint,
            startPointName: startPointName
        )
    }

    // MARK: - Foundation Models実装

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateWithFoundationModels(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place],
        startPoint: Place
    ) async throws -> GeneratedPlan {
        guard SystemLanguageModel.default.isAvailable else {
            throw PlanGeneratorError.aiUnavailable
        }

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

            AppLogger.ai.info("Foundation Modelsでプラン生成完了: タイトル=\(generatedPlan.title), スポット数=\(generatedPlan.spots.count)")
            return generatedPlan
        } catch let error as PlanGeneratorError {
            throw error
        } catch {
            AppLogger.ai.error("Foundation Modelsでプラン生成に失敗: \(error.localizedDescription)")
            throw PlanGeneratorError.generationFailed(underlying: error)
        }
    }
    #endif

    // MARK: - Web API実装

    private func generateWithWebAPI(
        theme: String,
        categories: [PlanCategory],
        candidatePlaces: [Place],
        startPoint: Place,
        startPointName: String?
    ) async throws -> GeneratedPlan {
        // Web APIでルート最適化パイプラインを実行
        // startPointNameが提供されていればそれを使用、なければstartPoint.nameを使用
        let actualStartPointName = startPointName ?? startPoint.name
        let categoryNames = categories.map { $0.rawValue }.joined(separator: "、")
        let purpose = "\(theme)（カテゴリ: \(categoryNames)）"

        let request = PipelineRequest(
            startPoint: actualStartPointName,
            purpose: purpose,
            spotCount: 5,  // デフォルト5箇所
            model: "qwen"  // 固定でqwenを使用
        )

        do {
            let response = try await webAPIClient.generatePlan(request: request)

            // レスポンスからルート生成結果を取得
            guard let routeName = response.routeGeneration.routeName,
                  let spots = response.routeGeneration.spots,
                  !spots.isEmpty else {
                throw PlanGeneratorError.noSpotsGenerated
            }

            AppLogger.ai.info("Web APIパイプライン完了: タイトル=\(routeName), スポット数=\(spots.count)")

            // Web APIのスポット情報をGeneratedSpotInfoに変換
            // NOTE: 座標情報はgeocoding.placesに含まれているが、
            // GeneratedPlanには座標を含めないため、ここでは使用しない
            // 座標は後続の処理（ViewModel等）で使用される
            let generatedSpots = spots.map { spot in
                GeneratedSpotInfo(
                    name: spot.name,
                    description: spot.description ?? "",
                    stayMinutes: 60  // デフォルト60分
                )
            }

            let generatedPlan = GeneratedPlan(
                title: routeName,
                spots: generatedSpots
            )

            AppLogger.ai.info("Web APIでプラン生成完了: タイトル=\(generatedPlan.title), スポット数=\(generatedPlan.spots.count)")

            // ジオコーディング結果をキャッシュに保存
            if let places = response.geocoding.places {
                lastWebAPIGeocodingPlaces = places
                AppLogger.ai.debug("ジオコーディング結果をキャッシュ: \(places.count)件")
                for place in places {
                    let displayName = place.spotName ?? place.inputAddress
                    AppLogger.ai.debug("  - \(displayName): (\(place.location.latitude), \(place.location.longitude))")
                }
            }

            return generatedPlan

        } catch let error as WebAPIClient.WebAPIError {
            AppLogger.ai.error("Web API経由のプラン生成に失敗: \(error.localizedDescription)")
            throw PlanGeneratorError.generationFailed(underlying: error)
        } catch {
            AppLogger.ai.error("予期しないエラー: \(error.localizedDescription)")
            throw PlanGeneratorError.generationFailed(underlying: error)
        }
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

    /// Web APIのジオコーディング結果からPlaceオブジェクトを生成する
    ///
    /// `generateWithWebAPI`メソッド呼び出し後に使用して、
    /// Web APIで取得した座標情報から`Place`オブジェクトを作成します。
    ///
    /// - Parameter generatedSpots: AI生成されたスポット情報
    /// - Returns: Web APIの座標情報を使用した`Place`オブジェクトの配列
    func getPlacesFromWebAPIResult(generatedSpots: [GeneratedSpotInfo]) -> [Place] {
        guard let geocodedPlaces = lastWebAPIGeocodingPlaces else {
            AppLogger.ai.warning("Web APIのジオコーディング結果がありません")
            return []
        }

        var places: [Place] = []

        // 生成されたスポット順に、対応するジオコーディング結果を検索
        for generatedSpot in generatedSpots {
            // スポット名で一致するジオコーディング結果を検索
            // まずspotNameで完全一致、次にinputAddressで部分一致
            if let geocodedPlace = geocodedPlaces.first(where: { geocoded in
                if let spotName = geocoded.spotName {
                    return spotName == generatedSpot.name
                }
                return geocoded.inputAddress.contains(generatedSpot.name) ||
                       generatedSpot.name.contains(geocoded.inputAddress)
            }) {
                // MKPlacemarkを作成
                let coordinate = CLLocationCoordinate2D(
                    latitude: geocodedPlace.location.latitude,
                    longitude: geocodedPlace.location.longitude
                )
                let placemark = MKPlacemark(coordinate: coordinate)

                // MKMapItemを作成
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = generatedSpot.name

                // Placeオブジェクトを作成
                let place = Place(mapItem: mapItem)
                places.append(place)

                AppLogger.ai.debug("Web API結果からPlaceを作成: \(generatedSpot.name) (\(coordinate.latitude), \(coordinate.longitude))")
            } else {
                AppLogger.ai.warning("ジオコーディング結果が見つかりません: \(generatedSpot.name)")
            }
        }

        AppLogger.ai.info("Web API結果から\(places.count)件のPlaceを作成しました")
        return places
    }
}
