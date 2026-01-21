package com.fumiyakume.viewer.ui.scenariowriter

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.automirrored.filled.MergeType
import androidx.compose.material.icons.filled.Route
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material.icons.filled.Timeline
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * シナリオライターのタブ定義
 *
 * NavigationRailで表示される8つのタブを定義
 * macOS版と同じ機能を提供
 */
enum class ScenarioWriterTab(
    val label: String,
    val icon: ImageVector,
    val description: String
) {
    PIPELINE(
        label = "Pipeline",
        icon = Icons.Default.Timeline,
        description = "E2Eパイプライン実行"
    ),
    ROUTE_GENERATE(
        label = "ルート生成",
        icon = Icons.Default.Route,
        description = "AIでルートを生成"
    ),
    SCENARIO_GENERATE(
        label = "シナリオ生成",
        icon = Icons.Default.Description,
        description = "スポットのシナリオを生成"
    ),
    SCENARIO_INTEGRATE(
        label = "シナリオ統合",
        icon = Icons.AutoMirrored.Filled.MergeType,
        description = "複数シナリオを統合"
    ),
    SCENARIO_MAP(
        label = "マップ",
        icon = Icons.Default.Map,
        description = "スポットをマップに表示"
    ),
    TEXT_GENERATION(
        label = "テキスト生成",
        icon = Icons.Default.TextFields,
        description = "AIでテキストを生成"
    ),
    GEOCODE(
        label = "ジオコード",
        icon = Icons.Default.LocationOn,
        description = "住所から座標を取得"
    ),
    ROUTE_OPTIMIZE(
        label = "ルート最適化",
        icon = Icons.Default.Timeline,
        description = "ルート順序を最適化"
    );
}

/**
 * AIモデル選択
 */
enum class AIModel(val value: String, val displayName: String) {
    GEMINI("gemini", "Gemini"),
    QWEN("qwen", "Qwen")
}

/**
 * シナリオ生成モデル選択
 */
enum class ScenarioModels(val value: String, val displayName: String) {
    GEMINI("gemini", "Gemini のみ"),
    QWEN("qwen", "Qwen のみ"),
    BOTH("both", "両方")
}

/**
 * 移動モード
 */
enum class TravelMode(val value: String, val displayName: String) {
    DRIVE("DRIVE", "車"),
    WALK("WALK", "徒歩"),
    BICYCLE("BICYCLE", "自転車"),
    TRANSIT("TRANSIT", "公共交通機関")
}

/**
 * スポットタイプ
 */
enum class SpotType(val value: String, val displayName: String) {
    START("start", "出発地"),
    WAYPOINT("waypoint", "経由地"),
    DESTINATION("destination", "目的地")
}
