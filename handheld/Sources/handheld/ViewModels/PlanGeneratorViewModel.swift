import Foundation
import MapKit
import Observation
import SwiftData
import os

/// プラン生成ウィザードのステップを表す列挙型。
enum PlanGeneratorStep: Int, CaseIterable {
    /// エリア選択ステップ。
    case location = 0
    /// カテゴリ選択ステップ。
    case category = 1
    /// テーマ設定ステップ。
    case theme = 2
    /// 確認ステップ。
    case confirm = 3

    /// ステップのタイトル。
    var title: String {
        switch self {
        case .location: return "エリア選択"
        case .category: return "カテゴリ選択"
        case .theme: return "テーマ設定"
        case .confirm: return "確認"
        }
    }

    /// 最初のステップかどうか。
    var isFirst: Bool { self == .location }
    /// 最後のステップかどうか。
    var isLast: Bool { self == .confirm }
}

/// プラン生成の状態を表す列挙型。
enum PlanGeneratorState: Equatable {
    /// 待機状態。
    case idle
    /// スポット検索中。
    case searchingSpots
    /// AIプラン生成中。
    case generatingPlan
    /// ルート計算中。
    case calculatingRoutes
    /// 完了。
    case completed
    /// エラー発生。
    case error(message: String)

    /// 現在の進捗メッセージ。
    var progressMessage: String {
        switch self {
        case .idle: return ""
        case .searchingSpots: return "スポット検索中..."
        case .generatingPlan: return "AI生成中..."
        case .calculatingRoutes: return "ルート計算中..."
        case .completed: return "完了"
        case .error(let message): return message
        }
    }

    /// 進捗ステップ番号（0-3）。
    var progressStep: Int {
        switch self {
        case .idle: return 0
        case .searchingSpots: return 1
        case .generatingPlan: return 2
        case .calculatingRoutes: return 3
        case .completed: return 3
        case .error: return 0
        }
    }
}

/// プラン生成画面のViewModel。
///
/// プラン生成のステップ管理、検索、AI生成、ルート計算を統括します。
/// `@Observable`マクロを使用してSwiftUIビューとバインドします。
///
/// ## 概要
///
/// プラン生成は以下の4ステップで進行します：
/// 1. エリア選択（``PlanGeneratorStep/location``）
/// 2. カテゴリ選択（``PlanGeneratorStep/category``）
/// 3. テーマ設定（``PlanGeneratorStep/theme``）
/// 4. 確認（``PlanGeneratorStep/confirm``）
///
/// ## 使用例
///
/// ```swift
/// struct PlanGeneratorView: View {
///     @State private var viewModel = PlanGeneratorViewModel()
///
///     var body: some View {
///         switch viewModel.currentStep {
///         case .location:
///             LocationStepView(viewModel: viewModel)
///         // ...
///         }
///     }
/// }
/// ```
///
/// - SeeAlso: ``PlanGeneratorStep``, ``PlanGeneratorState``
@Observable
@MainActor
final class PlanGeneratorViewModel {
    // MARK: - 入力状態

    /// 現在のステップ。
    var currentStep: PlanGeneratorStep = .location
    /// エリア検索クエリ。
    var locationQuery: String = ""
    /// 選択されたエリア。
    var selectedLocation: Place?
    /// 検索半径。
    var searchRadius: SearchRadius = .large
    /// 選択されたカテゴリ。
    var selectedCategories: Set<PlanCategory> = []
    /// プランのテーマ。
    var theme: String = ""
    /// 開始予定時刻。
    var startTime: Date?
    /// 開始時刻を使用するかどうか。
    var useStartTime: Bool = false

    // MARK: - 検索状態

    /// エリア検索結果。
    var locationSuggestions: [Place] = []
    /// エリア検索中かどうか。
    var isSearchingLocation: Bool = false

    // MARK: - 生成状態

    /// 現在の生成状態。
    var generatorState: PlanGeneratorState = .idle
    /// 検索された候補地。
    var candidatePlaces: [Place] = []
    /// 生成されたプラン。
    var generatedPlan: SightseeingPlan?
    /// 生成されたスポット。
    var generatedSpots: [PlanSpot] = []
    /// スポット間のルート。
    var spotRoutes: [SpotRoute] = []

    // MARK: - 結果表示状態

    /// 結果表示モード。
    enum ViewMode: String, CaseIterable, Identifiable {
        case timeline = "タイムライン"
        case map = "地図"
        case list = "リスト"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .timeline: return "clock"
            case .map: return "map"
            case .list: return "list.bullet"
            }
        }
    }
    /// 現在の表示モード。
    var viewMode: ViewMode = .timeline
    /// 詳細表示中のスポット。
    var selectedSpotForDetail: PlanSpot?
    /// スポット詳細シートを表示するか。
    var showSpotDetailSheet: Bool = false
    /// スポット追加シートを表示するか。
    var showAddSpotSheet: Bool = false
    /// タイトル編集中かどうか。
    var isEditingTitle: Bool = false
    /// 編集中のタイトル。
    var editedTitle: String = ""

    // MARK: - サービス

    private let locationSearchService: LocationSearchServiceProtocol
    private let spotSearchService: SpotSearchServiceProtocol
    private let planRouteService: PlanRouteServiceProtocol
    private let planGeneratorService: PlanGeneratorServiceProtocol
    private let completerService: LocationCompleterServiceProtocol

    /// Apple Intelligenceが利用可能かどうか。
    var isAIAvailable: Bool {
        planGeneratorService.isAvailable
    }

    /// ViewModelを初期化する。
    ///
    /// - Parameters:
    ///   - locationSearchService: エリア検索サービス
    ///   - spotSearchService: スポット検索サービス
    ///   - planRouteService: ルート計算サービス
    ///   - planGeneratorService: プラン生成サービス
    ///   - completerService: 入力補完サービス
    init(
        locationSearchService: LocationSearchServiceProtocol = LocationSearchService(),
        spotSearchService: SpotSearchServiceProtocol = SpotSearchService(),
        planRouteService: PlanRouteServiceProtocol = PlanRouteService(),
        planGeneratorService: PlanGeneratorServiceProtocol = PlanGeneratorService(),
        completerService: LocationCompleterServiceProtocol = LocationCompleterService()
    ) {
        self.locationSearchService = locationSearchService
        self.spotSearchService = spotSearchService
        self.planRouteService = planRouteService
        self.planGeneratorService = planGeneratorService
        self.completerService = completerService
    }

    // MARK: - ナビゲーション

    /// 次のステップに進めるかどうか。
    var canProceedToNext: Bool {
        switch currentStep {
        case .location:
            return selectedLocation != nil
        case .category:
            return !selectedCategories.isEmpty
        case .theme:
            return !theme.trimmingCharacters(in: .whitespaces).isEmpty
        case .confirm:
            return true
        }
    }

    /// 次のステップに進む。
    func nextStep() {
        guard let next = PlanGeneratorStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    /// 前のステップに戻る。
    func previousStep() {
        guard let prev = PlanGeneratorStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    // MARK: - エリア検索

    /// エリアを検索する。
    @MainActor
    func searchLocation() async {
        guard !locationQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            locationSuggestions = []
            return
        }

        isSearchingLocation = true
        defer { isSearchingLocation = false }

        do {
            locationSuggestions = try await locationSearchService.search(query: locationQuery, region: nil)
        } catch {
            AppLogger.search.error("エリア検索に失敗: \(error.localizedDescription)")
            locationSuggestions = []
        }
    }

    /// エリアを選択する。
    ///
    /// - Parameter place: 選択するエリア
    func selectLocation(_ place: Place) {
        selectedLocation = place
        locationQuery = place.name
        locationSuggestions = []
    }

    // MARK: - カテゴリ選択

    /// カテゴリの選択を切り替える。
    ///
    /// - Parameter category: 切り替えるカテゴリ
    func toggleCategory(_ category: PlanCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    var availableSuggestions: [String] {
        var suggestions: [String] = []
        for category in selectedCategories {
            suggestions.append(contentsOf: category.suggestions)
        }
        return suggestions
    }

    /// テーマサジェストを選択する。
    ///
    /// - Parameter suggestion: 選択するサジェスト文字列
    func selectThemeSuggestion(_ suggestion: String) {
        theme = suggestion
    }

    // MARK: - プラン生成

    /// プランを生成する。
    ///
    /// スポット検索、AI生成、ルート計算を順次実行します。
    @MainActor
    func generatePlan() async {
        guard let location = selectedLocation else { return }

        generatorState = .searchingSpots

        do {
            candidatePlaces = try await spotSearchService.searchSpots(
                theme: theme,
                categories: Array(selectedCategories),
                centerCoordinate: location.coordinate,
                radius: searchRadius
            )

            guard candidatePlaces.count >= 3 else {
                generatorState = .error(message: "候補地が不足しています（\(candidatePlaces.count)件）。範囲を広げてお試しください。")
                return
            }

            generatorState = .generatingPlan

            let generated = try await planGeneratorService.generatePlan(
                theme: theme,
                categories: Array(selectedCategories),
                candidatePlaces: candidatePlaces,
                startPoint: location,
                startPointName: locationQuery  // Web版と同じように、ユーザー入力文字列をそのまま使用
            )

            // Web API使用時とFoundation Models使用時で処理を分岐
            let matchedSpots: [(spot: GeneratedSpotInfo, place: Place)]

            if planGeneratorService.usedWebAPI {
                // Web API使用時: ジオコーディング結果から直接Placeオブジェクトを作成
                AppLogger.ai.info("Web API結果からPlaceオブジェクトを生成")
                let places = planGeneratorService.getPlacesFromWebAPIResult(generatedSpots: generated.spots)

                guard !places.isEmpty else {
                    generatorState = .error(message: "Web APIから座標情報を取得できませんでした。再度お試しください。")
                    return
                }

                // GeneratedSpotInfoとPlaceを組み合わせる
                matchedSpots = zip(generated.spots, places).map { (spot: $0, place: $1) }
            } else {
                // Foundation Models使用時: 候補地リストとマッチング
                AppLogger.ai.info("候補地リストとマッチング")
                matchedSpots = planGeneratorService.matchGeneratedSpotsWithPlaces(
                    generatedSpots: generated.spots,
                    candidatePlaces: candidatePlaces
                )

                guard !matchedSpots.isEmpty else {
                    generatorState = .error(message: "スポットのマッチングに失敗しました。再度お試しください。")
                    return
                }
            }

            // 座標検証 - 検索範囲内のスポットのみ許可（50%のマージン）
            let centerLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let maxDistanceMeters = searchRadius.meters * 1.5

            let validatedSpots = matchedSpots.filter { matched in
                let spotLocation = CLLocation(latitude: matched.place.coordinate.latitude, longitude: matched.place.coordinate.longitude)
                let distance = centerLocation.distance(from: spotLocation)

                if distance > maxDistanceMeters {
                    AppLogger.ai.warning("スポット '\(matched.place.name)' は検索範囲外です (距離: \(Int(distance))m)")
                    return false
                }
                return true
            }

            guard validatedSpots.count >= 3 else {
                generatorState = .error(message: "検索範囲内のスポットが不足しています（\(validatedSpots.count)件）。範囲を広げてお試しください。")
                return
            }

            generatedSpots = validatedSpots.enumerated().map { index, matched in
                PlanSpot(
                    order: index,
                    name: matched.place.name,
                    address: matched.place.address,
                    coordinate: matched.place.coordinate,
                    aiDescription: matched.spot.description,
                    estimatedStayDuration: TimeInterval(matched.spot.stayMinutes * 60)
                )
            }

            generatorState = .calculatingRoutes

            let routeResult = try await planRouteService.calculateRoutes(for: generatedSpots)
            spotRoutes = routeResult.routes

            // 部分的失敗を警告として記録
            if routeResult.hasPartialFailure {
                let failedPairs = routeResult.failures.map { "\($0.fromSpotName) → \($0.toSpotName)" }.joined(separator: ", ")
                AppLogger.directions.warning("一部ルートの計算に失敗: \(failedPairs)")
            }

            planRouteService.updateSpotRouteInfo(spots: &generatedSpots, routes: spotRoutes)

            let (totalDistance, totalDuration) = planRouteService.calculateTotalMetrics(
                from: spotRoutes,
                spots: generatedSpots
            )

            generatedPlan = SightseeingPlan(
                title: generated.title,
                theme: theme,
                categories: Array(selectedCategories),
                searchRadius: searchRadius,
                centerCoordinate: location.coordinate,
                startTime: useStartTime ? startTime : nil,
                spots: generatedSpots
            )
            generatedPlan?.totalDistance = totalDistance
            generatedPlan?.totalDuration = totalDuration

            generatorState = .completed

        } catch let error as PlanGeneratorError {
            generatorState = .error(message: error.errorDescription ?? "不明なエラー")
        } catch {
            AppLogger.ai.error("プラン生成に失敗: \(error.localizedDescription)")
            generatorState = .error(message: "プラン生成に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - 編集

    /// スポットの順序を変更する。
    ///
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    func reorderSpots(from source: IndexSet, to destination: Int) {
        generatedSpots.move(fromOffsets: source, toOffset: destination)
        updateSpotOrders()
    }

    /// 指定インデックスのスポットを削除する。
    ///
    /// - Parameter offsets: 削除するインデックス
    func deleteSpot(at offsets: IndexSet) {
        generatedSpots.remove(atOffsets: offsets)
        updateSpotOrders()
    }

    /// スポットを削除する。
    ///
    /// - Parameter spot: 削除するスポット
    func deleteSpot(_ spot: PlanSpot) {
        if let index = generatedSpots.firstIndex(where: { $0.id == spot.id }) {
            generatedSpots.remove(at: index)
            updateSpotOrders()
        }
    }

    private func updateSpotOrders() {
        for (index, _) in generatedSpots.enumerated() {
            generatedSpots[index].order = index
        }
    }

    /// スポットの滞在時間を変更する。
    ///
    /// - Parameters:
    ///   - spot: 対象のスポット
    ///   - minutes: 変更する分数（正負）
    func updateStayDuration(for spot: PlanSpot, by minutes: Int) {
        guard let index = generatedSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        let newDuration = generatedSpots[index].estimatedStayDuration + TimeInterval(minutes * 60)
        if newDuration >= 15 * 60 && newDuration <= 180 * 60 {
            generatedSpots[index].estimatedStayDuration = newDuration
        }
    }

    /// スポットのお気に入り状態を切り替える。
    ///
    /// - Parameter spot: 対象のスポット
    func toggleFavorite(for spot: PlanSpot) {
        guard let index = generatedSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        generatedSpots[index].isFavorite.toggle()
    }

    /// タイトル編集を開始する。
    func startEditingTitle() {
        editedTitle = generatedPlan?.title ?? ""
        isEditingTitle = true
    }

    /// タイトルを保存する。
    func saveTitle() {
        generatedPlan?.title = editedTitle
        isEditingTitle = false
    }

    /// スポット詳細を表示する。
    ///
    /// - Parameter spot: 表示するスポット
    func showSpotDetail(_ spot: PlanSpot) {
        selectedSpotForDetail = spot
        showSpotDetailSheet = true
    }

    // MARK: - スポット追加

    /// スポットを追加する。
    ///
    /// - Parameter place: 追加する場所
    func addSpot(_ place: Place) {
        let newSpot = PlanSpot(
            order: generatedSpots.count,
            name: place.name,
            address: place.address,
            coordinate: place.coordinate,
            aiDescription: "",
            estimatedStayDuration: 30 * 60
        )
        generatedSpots.append(newSpot)
        showAddSpotSheet = false
    }

    // MARK: - ルート再計算

    /// ルートを再計算する。
    ///
    /// スポット追加・削除・並び替え後に呼び出します。
    @MainActor
    func recalculateRoutes() async {
        generatorState = .calculatingRoutes

        do {
            let routeResult = try await planRouteService.calculateRoutes(for: generatedSpots)
            spotRoutes = routeResult.routes

            // 部分的失敗を警告として記録
            if routeResult.hasPartialFailure {
                let failedPairs = routeResult.failures.map { "\($0.fromSpotName) → \($0.toSpotName)" }.joined(separator: ", ")
                AppLogger.directions.warning("一部ルートの再計算に失敗: \(failedPairs)")
            }

            planRouteService.updateSpotRouteInfo(spots: &generatedSpots, routes: spotRoutes)

            let (totalDistance, totalDuration) = planRouteService.calculateTotalMetrics(
                from: spotRoutes,
                spots: generatedSpots
            )
            generatedPlan?.totalDistance = totalDistance
            generatedPlan?.totalDuration = totalDuration

            generatorState = .completed
        } catch {
            generatorState = .error(message: "ルート再計算に失敗しました")
        }
    }

    // MARK: - 保存

    /// プランをSwiftDataに保存する。
    ///
    /// - Parameter context: SwiftDataのモデルコンテキスト
    @MainActor
    func savePlan(context: ModelContext) {
        guard let plan = generatedPlan else { return }

        plan.spots = generatedSpots
        plan.updatedAt = Date()

        context.insert(plan)

        do {
            try context.save()
            AppLogger.data.info("プランを保存しました: \(plan.title)")
        } catch {
            AppLogger.data.error("プランの保存に失敗: \(error.localizedDescription)")
        }
    }

    /// お気に入りスポットをSwiftDataに保存する。
    ///
    /// - Parameter context: SwiftDataのモデルコンテキスト
    func saveFavoriteSpots(context: ModelContext) {
        let favoriteSpots = generatedSpots.filter { $0.isFavorite }

        for spot in favoriteSpots {
            let favoriteSpot = FavoriteSpot(from: spot)
            context.insert(favoriteSpot)
        }

        do {
            try context.save()
            AppLogger.data.info("お気に入りスポットを保存しました: \(favoriteSpots.count)件")
        } catch {
            AppLogger.data.error("お気に入りスポットの保存に失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - リセット

    /// ViewModelの状態を初期化する。
    func reset() {
        currentStep = .location
        locationQuery = ""
        selectedLocation = nil
        searchRadius = .large
        selectedCategories = []
        theme = ""
        startTime = nil
        useStartTime = false
        generatorState = .idle
        candidatePlaces = []
        generatedPlan = nil
        generatedSpots = []
        spotRoutes = []
        viewMode = .timeline
    }

    // MARK: - 共有

    /// Apple Mapsでルートを開く。
    func openInAppleMaps() {
        guard !generatedSpots.isEmpty else { return }

        var urlString = "maps://?"

        let destinations = generatedSpots.map { spot in
            "\(spot.latitude),\(spot.longitude)"
        }.joined(separator: "&daddr=")

        urlString += "daddr=\(destinations)&dirflg=d"

        if let url = URL(string: urlString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }

    // MARK: - 地図表示用

    /// 全ルートのポリライン配列。
    var routePolylines: [MKPolyline] {
        spotRoutes.map { $0.route.polyline }
    }
}
