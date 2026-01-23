package com.fumiyakume.viewer.ui.scenariowriter.tabs

import com.fumiyakume.viewer.ui.scenariowriter.AIModel
import com.fumiyakume.viewer.ui.scenariowriter.SpotType
import com.fumiyakume.viewer.ui.scenariowriter.TravelMode
import com.fumiyakume.viewer.data.network.ScenarioIntegrationOutput
import com.fumiyakume.viewer.data.network.ScenarioOutput
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ScenarioWriterTabsTest {

    @Test
    fun pipelineHelpers_formatValuesAndLabels() {
        assertEquals("実行中...", pipelineButtonLabel(true))
        assertEquals("パイプライン実行", pipelineButtonLabel(false))
        assertEquals("12.3 km", formatPipelineDistanceKm(12.34))
        assertEquals("45 分", formatPipelineDurationMinutes(45))
        assertEquals("900 ms", formatPipelineProcessingTimeMs(900))
    }

    @Test
    fun textGenerationHelpers_formatLabels() {
        assertEquals("生成中...", textGenerationButtonLabel(true))
        assertEquals("生成", textGenerationButtonLabel(false))
        assertEquals("使用モデル: Gemini", textGenerationModelLabel(AIModel.GEMINI))
        assertNull(textGenerationModelLabel(null))
    }

    @Test
    fun routeOptimizeHelpers_formatValuesAndLabels() {
        assertEquals("最適化中...", routeOptimizeButtonLabel(true))
        assertEquals("ルート最適化", routeOptimizeButtonLabel(false))
        assertEquals("7.5 km", formatRouteDistanceKm(7.49))
        assertEquals("30 分", formatRouteDurationMinutes(30))
    }

    @Test
    fun geocodeHelpers_formatValuesAndLabels() {
        assertEquals("ジオコーディング中...", geocodeButtonLabel(true))
        assertEquals("ジオコーディング", geocodeButtonLabel(false))
        assertEquals("35.681236", formatCoordinate(35.681236))
        assertEquals("2 件の住所を変換しました", formatGeocodeResultCount(2))
    }

    @Test
    fun spotTypeLabel_returnsDisplayNameWhenKnown() {
        assertEquals(SpotType.START.displayName, spotTypeLabel(SpotType.START.value))
        assertEquals("custom", spotTypeLabel("custom"))
    }

    @Test
    fun createRouteSpot_returnsNullWhenNameBlank() {
        val spot = createRouteSpot(
            name = " ",
            type = SpotType.WAYPOINT,
            description = "desc",
            point = "point"
        )

        assertEquals(null, spot)
    }

    @Test
    fun createRouteSpot_buildsRouteSpotWithOptionalFields() {
        val spot = createRouteSpot(
            name = "皇居",
            type = SpotType.DESTINATION,
            description = "",
            point = "歴史"
        )

        requireNotNull(spot)
        assertEquals("皇居", spot.name)
        assertEquals(SpotType.DESTINATION.value, spot.type)
        assertEquals(null, spot.description)
        assertEquals("歴史", spot.point)
    }

    @Test
    fun scenarioSuccessLabel_defaultsNullCountsToZero() {
        assertEquals("成功: 0/0", scenarioSuccessLabel(null, null))
        assertEquals("成功: 2/5", scenarioSuccessLabel(2, 5))
    }

    @Test
    fun formatSpotListTitle_formatsCount() {
        assertEquals("スポットリスト (0件)", formatSpotListTitle(0))
        assertEquals("スポットリスト (3件)", formatSpotListTitle(3))
    }

    @Test
    fun buildTravelModeOptions_marksSelectedMode() {
        val options = buildTravelModeOptions(TravelMode.WALK)

        assertEquals(TravelMode.entries.size, options.size)
        assertEquals(TravelMode.WALK, options.first { it.value == TravelMode.WALK }.value)
        assertEquals(true, options.first { it.value == TravelMode.WALK }.isSelected)
    }

    @Test
    fun markerHue_respectsSelectionAndType() {
        assertEquals(30f, markerHue("waypoint", isSelected = true))
        assertEquals(120f, markerHue("start", isSelected = false))
        assertEquals(0f, markerHue("destination", isSelected = false))
        assertEquals(210f, markerHue("unknown", isSelected = false))
    }

    @Test
    fun mapSpotLabel_formatsLabel() {
        assertEquals("1. 東京駅", mapSpotLabel(0, "東京駅"))
    }

    @Test
    fun mapSpotTypeLabel_returnsType() {
        assertEquals("start", mapSpotTypeLabel("start"))
    }

    @Test
    fun mapSpotCoordinateLabel_formatsCoordinates() {
        assertEquals("座標: 35.681236, 139.767125", mapSpotCoordinateLabel(35.681236, 139.767125))
    }

    @Test
    fun routeGenerateHelpers_formatLabels() {
        assertEquals("生成中...", routeGenerateButtonLabel(true))
        assertEquals("AIでルート生成", routeGenerateButtonLabel(false))
        assertEquals("生成モデル: gemini", routeGenerateModelLabel("gemini"))
        assertEquals("1. 東京駅", routeGenerateSpotLabel(0, "東京駅"))
        assertEquals("タイプ: start", routeGenerateSpotTypeLabel("start"))
    }

    @Test
    fun scenarioIntegrateHelpers_formatLabels() {
        assertEquals("統合中...", scenarioIntegrateButtonLabel(true))
        assertEquals("シナリオを統合", scenarioIntegrateButtonLabel(false))
        assertEquals("処理時間: 1200ms", scenarioIntegrateProcessingTimeLabel(1200))
    }

    @Test
    fun resolveScenarioIntegrateState_handlesNulls() {
        assertEquals(
            ScenarioIntegrateState.NoScenarioResult,
            resolveScenarioIntegrateState(null, null)
        )
        assertEquals(
            ScenarioIntegrateState.ReadyToIntegrate,
            resolveScenarioIntegrateState(ScenarioOutput(success = true), null)
        )
        assertEquals(
            ScenarioIntegrateState.HasIntegrationResult,
            resolveScenarioIntegrateState(
                ScenarioOutput(success = true),
                ScenarioIntegrationOutput(success = true)
            )
        )
    }

    @Test
    fun pipelineResultHelpers_formatLabels() {
        assertEquals("結果がありません", pipelineResultEmptyLabel())
        assertEquals("route", pipelineRouteNameLabel("route"))
        assertEquals("生成されたスポット", pipelineSpotHeaderLabel())
        assertEquals("1. 東京駅", pipelineSpotLabel(0, "東京駅"))
        assertEquals("desc", pipelineSpotDescriptionLabel("desc"))
        assertEquals("note", pipelineSpotNoteLabel("note"))
        assertEquals("総距離: 1.2 km", pipelineDistanceLabel(1.23))
        assertEquals("所要時間: 12 分", pipelineDurationLabel(12))
        assertEquals("処理時間: 500 ms", pipelineProcessingTimeLabel(500))
        assertEquals("マップで表示", pipelineShowOnMapLabel())
        assertEquals("シナリオを生成", pipelineGenerateScenarioLabel())
        assertEquals("入力", pipelineInputTitle())
        assertEquals("結果", pipelineResultTitle())
        assertEquals("出発地", pipelineStartPointLabel())
        assertEquals("目的・テーマ", pipelinePurposeLabel())
        assertEquals("生成地点数", pipelineSpotCountLabel())
        assertEquals("例: 東京駅", pipelineStartPointPlaceholder())
        assertEquals("例: 皇居周辺の観光スポット", pipelinePurposePlaceholder())
    }

    @Test
    fun scenarioGenerateLabels_areExpected() {
        assertEquals("スポットがありません", scenarioSpotListEmptyLabel())
        assertEquals("結果がありません", scenarioGenerateResultEmptyLabel())
        assertEquals("シナリオ統合へ", scenarioIntegrateActionLabel())
        assertEquals("ルート: sample", scenarioRouteLabel("sample"))
        assertEquals("折りたたむ", spotScenarioToggleLabel(true))
        assertEquals("展開する", spotScenarioToggleLabel(false))
        assertEquals("エラー: bad", spotScenarioErrorLabel("bad"))
        assertEquals("入力", scenarioGenerateInputTitle())
        assertEquals("スポット追加", scenarioGenerateSpotAddTitle())
        assertEquals("結果", scenarioGenerateResultTitle())
        assertEquals("言語（オプション）", scenarioLanguageLabel())
        assertEquals("例: ja", scenarioLanguagePlaceholder())
        assertEquals("ルート名", scenarioRouteNameLabel())
        assertEquals("例: 皇居周辺観光ルート", scenarioRouteNamePlaceholder())
        assertEquals("スポット名", scenarioSpotNameLabel())
        assertEquals("例: 皇居", scenarioSpotNamePlaceholder())
        assertEquals("スポットタイプ", scenarioSpotTypeLabel())
        assertEquals("説明（オプション）", scenarioSpotDescriptionLabel())
        assertEquals("例: 江戸城の跡地", scenarioSpotDescriptionPlaceholder())
        assertEquals("ポイント（オプション）", scenarioSpotPointLabel())
        assertEquals("例: 歴史的建造物", scenarioSpotPointPlaceholder())
        assertEquals("追加", scenarioSpotAddButtonLabel())
        assertEquals("生成中...", scenarioGenerateButtonLabel(true))
        assertEquals("シナリオ生成", scenarioGenerateButtonLabel(false))
    }

    @Test
    fun routeOptimizeLabels_areExpected() {
        assertEquals("ウェイポイントがありません", routeOptimizeEmptyWaypointsLabel())
        assertEquals("少なくとも2つのウェイポイントが必要です", routeOptimizeMinWaypointsLabel())
        assertEquals("結果がありません", routeOptimizeResultEmptyLabel())
        assertEquals("最適化されたルート順序", routeOptimizeOrderHeaderLabel())
        assertEquals("1. 東京駅", routeOptimizeOrderItemLabel(0, "東京駅"))
        assertEquals("総距離", routeOptimizeDistanceTitleLabel())
        assertEquals("所要時間", routeOptimizeDurationTitleLabel())
        assertEquals("12.3 km", routeOptimizeDistanceValueLabel(12.34))
        assertEquals("45 分", routeOptimizeDurationValueLabel(45))
        assertEquals("設定", routeOptimizeSettingsTitle())
        assertEquals("ウェイポイント追加", routeOptimizeWaypointAddTitle())
        assertEquals("ウェイポイントリスト (2件)", routeOptimizeWaypointListTitle(2))
        assertEquals("結果", routeOptimizeResultTitle())
    }

    @Test
    fun textGenerationResultLabel_isExpected() {
        assertEquals("結果がありません", textGenerationResultEmptyLabel())
        assertEquals("入力", textGenerationInputTitle())
        assertEquals("結果", textGenerationResultTitle())
        assertEquals("プロンプト", textGenerationPromptLabel())
        assertEquals("AIに質問したい内容を入力してください", textGenerationPromptPlaceholder())
    }

    @Test
    fun routeGenerateLabels_areExpected() {
        assertEquals("結果がありません", routeGenerateResultEmptyLabel())
        assertEquals("生成されたスポット", routeGenerateSpotHeaderLabel())
        assertEquals("シナリオ生成へ", routeGenerateGoToScenarioLabel())
        assertEquals("入力", routeGenerateInputTitle())
        assertEquals("結果", routeGenerateResultTitle())
        assertEquals("出発地", routeGenerateStartPointLabel())
        assertEquals("目的・テーマ", routeGeneratePurposeLabel())
        assertEquals("生成地点数", routeGenerateSpotCountLabel())
        assertEquals("例: 東京駅", routeGenerateStartPointPlaceholder())
        assertEquals("例: 皇居周辺の観光スポット", routeGeneratePurposePlaceholder())
    }

    @Test
    fun geocodeLabels_areExpected() {
        assertEquals("複数の住所を改行で区切って入力してください", geocodeInstructionLabel())
        assertEquals("結果がありません", geocodeResultEmptyLabel())
        assertEquals("入力", geocodeInputTitle())
        assertEquals("結果", geocodeResultTitle())
        assertEquals("緯度", geocodeLatitudeLabel())
        assertEquals("経度", geocodeLongitudeLabel())
        assertEquals("住所リスト", geocodeAddressListLabel())
        assertEquals(
            "1行に1住所を入力\n例:\n東京都千代田区丸の内1丁目\n東京都渋谷区神南1丁目",
            geocodeAddressesPlaceholder()
        )
    }

    @Test
    fun scenarioMapLabels_areExpected() {
        assertEquals("スポット一覧", mapSpotListTitleLabel())
        assertEquals("マップに表示するデータがありません", mapEmptyTitleLabel())
        assertEquals(
            "Pipelineを実行して「マップで表示」をクリックしてください",
            mapEmptySubtitleLabel()
        )
        assertEquals("Pipelineタブへ", mapEmptyActionLabel())
        assertEquals("住所: 東京都", mapSpotAddressLabel("東京都"))
        assertEquals("説明", mapSpotDescriptionLabel("説明"))
        assertEquals("皇居", mapSpotInfoTitleLabel("皇居"))
        assertEquals(com.fumiyakume.viewer.ui.theme.TeslaColors.StatusGreen, mapSpotListMarkerColor("start"))
        assertEquals(com.fumiyakume.viewer.ui.theme.TeslaColors.Accent, mapSpotListMarkerColor("waypoint"))
        assertEquals(com.fumiyakume.viewer.ui.theme.TeslaColors.StatusRed, mapSpotListMarkerColor("destination"))
        assertEquals(com.fumiyakume.viewer.ui.theme.TeslaColors.TextSecondary, mapSpotListMarkerColor("other"))
        assertEquals(
            com.fumiyakume.viewer.ui.theme.TeslaColors.Accent.copy(alpha = 0.1f),
            mapSpotListBackgroundColor(true)
        )
        assertEquals(
            com.fumiyakume.viewer.ui.theme.TeslaColors.GlassBackground,
            mapSpotListBackgroundColor(false)
        )
    }

    @Test
    fun scenarioIntegrateLabels_areExpected() {
        assertEquals(
            "統合するシナリオがありません。まずシナリオ生成タブでシナリオを生成してください。",
            scenarioIntegrateNoScenarioMessage()
        )
        assertEquals("シナリオ生成タブへ", scenarioIntegrateGoToScenarioLabel())
        assertEquals("シナリオ統合", scenarioIntegrateTitleLabel())
        assertEquals("以下のシナリオを統合します", scenarioIntegrateIntroLabel())
        assertEquals("統合結果", scenarioIntegrateResultTitleLabel())
        assertEquals("AIによる統合シナリオ", scenarioIntegrateAiHeaderLabel())
        assertEquals("ルート: abc", scenarioIntegrateRouteLabel("abc"))
        assertEquals("モデル: gemini", scenarioIntegrateModelLabel("gemini"))
        assertEquals("統合日時: 2024-01-01", scenarioIntegrateIntegratedAtLabel("2024-01-01"))
        assertEquals("• spot", scenarioIntegrateSpotLabel("spot"))
    }
}
