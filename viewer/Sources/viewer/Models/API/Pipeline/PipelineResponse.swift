import Foundation

/// パイプライン実行レスポンス
struct PipelineResponse: Codable {
    let success: Bool
    let request: PipelineRequestInfo
    let routeGeneration: RouteGenerationStep
    let geocoding: GeocodingStep
    let routeOptimization: RouteOptimizationStep
    let totalProcessingTimeMs: Int
    let error: String?
}

/// リクエスト情報
struct PipelineRequestInfo: Codable {
    let startPoint: String
    let purpose: String
    let spotCount: Int
    let model: String
}

/// ルート生成ステップの結果
struct RouteGenerationStep: Codable {
    let status: String
    let processingTimeMs: Int?
    let routeName: String?
    let spots: [PipelineGeneratedSpot]?
    let error: String?
}

/// パイプラインで生成されたスポット
struct PipelineGeneratedSpot: Codable, Identifiable {
    let name: String
    let type: String
    let description: String?
    let generatedNote: String?

    var id: String { name }
}

/// ジオコーディングステップの結果
struct GeocodingStep: Codable {
    let status: String
    let processingTimeMs: Int?
    let places: [PipelineGeocodedPlace]?
    let failedSpots: [String]?
    let error: String?
}

/// ジオコーディングされた場所
struct PipelineGeocodedPlace: Codable, Identifiable {
    let inputAddress: String
    let formattedAddress: String
    let location: PipelineLatLng
    let placeId: String

    var id: String { placeId }
}

/// 緯度経度（パイプライン用）
struct PipelineLatLng: Codable {
    let latitude: Double
    let longitude: Double
}

/// ルート最適化ステップの結果
struct RouteOptimizationStep: Codable {
    let status: String
    let processingTimeMs: Int?
    let orderedWaypoints: [PipelineOrderedWaypoint]?
    let legs: [PipelineRouteLeg]?
    let totalDistanceMeters: Int?
    let totalDurationSeconds: Int?
    let error: String?
}

/// 最適化されたウェイポイント
struct PipelineOrderedWaypoint: Codable, Identifiable {
    let originalIndex: Int
    let optimizedOrder: Int
    let waypoint: PipelineWaypoint

    var id: Int { optimizedOrder }
}

/// ウェイポイント
struct PipelineWaypoint: Codable {
    let name: String?
    let placeId: String?
    let location: PipelineLatLng?
    let address: String?
}

/// ルート区間
struct PipelineRouteLeg: Codable {
    let fromIndex: Int
    let toIndex: Int
    let distanceMeters: Int
    let durationSeconds: Int
}
