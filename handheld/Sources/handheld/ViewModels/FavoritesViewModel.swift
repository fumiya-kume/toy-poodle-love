import Foundation
import Observation
import SwiftData
import os

/// お気に入り画面のタブ。
enum FavoritesTab: String, CaseIterable, Identifiable {
    /// プランタブ。
    case plans = "プラン"
    /// スポットタブ。
    case spots = "スポット"

    var id: String { rawValue }
}

/// お気に入り画面のViewModel。
///
/// 保存されたプランとお気に入りスポットの表示・削除を管理します。
/// `@Observable`マクロを使用してSwiftUIビューとバインドします。
///
/// ## 使用例
///
/// ```swift
/// struct FavoritesView: View {
///     @State private var viewModel = FavoritesViewModel()
///     @Environment(\.modelContext) private var modelContext
///
///     var body: some View {
///         List(viewModel.plans) { plan in
///             // ...
///         }
///         .onAppear {
///             viewModel.loadData(context: modelContext)
///         }
///     }
/// }
/// ```
///
/// - SeeAlso: ``FavoritesTab``, ``SightseeingPlan``, ``FavoriteSpot``
@Observable
final class FavoritesViewModel {
    /// 選択中のタブ。
    var selectedTab: FavoritesTab = .plans
    /// 保存されたプランのリスト。
    var plans: [SightseeingPlan] = []
    /// お気に入りスポットのリスト。
    var favoriteSpots: [FavoriteSpot] = []
    /// 選択中のプラン。
    var selectedPlan: SightseeingPlan?
    /// プラン詳細を表示するか。
    var showPlanDetail: Bool = false

    /// 現在のタブが空かどうか。
    var isEmpty: Bool {
        switch selectedTab {
        case .plans:
            return plans.isEmpty
        case .spots:
            return favoriteSpots.isEmpty
        }
    }

    /// 空の場合のメッセージ。
    var emptyMessage: String {
        switch selectedTab {
        case .plans:
            return "保存したプランがありません"
        case .spots:
            return "お気に入りスポットがありません"
        }
    }

    /// 空の場合のアイコン。
    var emptyIcon: String {
        switch selectedTab {
        case .plans:
            return "map"
        case .spots:
            return "heart"
        }
    }

    /// プランとお気に入りスポットを読み込む。
    ///
    /// - Parameter context: SwiftDataのモデルコンテキスト
    @MainActor
    func loadData(context: ModelContext) {
        loadPlans(context: context)
        loadFavoriteSpots(context: context)
    }

    /// プランを読み込む。
    ///
    /// - Parameter context: SwiftDataのモデルコンテキスト
    @MainActor
    func loadPlans(context: ModelContext) {
        let descriptor = FetchDescriptor<SightseeingPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            plans = try context.fetch(descriptor)
            AppLogger.data.info("プランを読み込みました: \(self.plans.count)件")
        } catch {
            AppLogger.data.error("プランの読み込みに失敗: \(error.localizedDescription)")
            plans = []
        }
    }

    /// お気に入りスポットを読み込む。
    ///
    /// - Parameter context: SwiftDataのモデルコンテキスト
    @MainActor
    func loadFavoriteSpots(context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteSpot>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )

        do {
            favoriteSpots = try context.fetch(descriptor)
            AppLogger.data.info("お気に入りスポットを読み込みました: \(self.favoriteSpots.count)件")
        } catch {
            AppLogger.data.error("お気に入りスポットの読み込みに失敗: \(error.localizedDescription)")
            favoriteSpots = []
        }
    }

    /// プランを削除する。
    ///
    /// - Parameters:
    ///   - plan: 削除するプラン
    ///   - context: SwiftDataのモデルコンテキスト
    @MainActor
    func deletePlan(_ plan: SightseeingPlan, context: ModelContext) {
        context.delete(plan)

        do {
            try context.save()
            loadPlans(context: context)
            AppLogger.data.info("プランを削除しました: \(plan.title)")
        } catch {
            AppLogger.data.error("プランの削除に失敗: \(error.localizedDescription)")
        }
    }

    /// 指定インデックスのプランを削除する。
    ///
    /// - Parameters:
    ///   - offsets: 削除するインデックス
    ///   - context: SwiftDataのモデルコンテキスト
    @MainActor
    func deletePlans(at offsets: IndexSet, context: ModelContext) {
        for index in offsets {
            let plan = plans[index]
            context.delete(plan)
        }

        do {
            try context.save()
            loadPlans(context: context)
        } catch {
            AppLogger.data.error("プランの削除に失敗: \(error.localizedDescription)")
        }
    }

    /// お気に入りスポットを削除する。
    ///
    /// - Parameters:
    ///   - spot: 削除するスポット
    ///   - context: SwiftDataのモデルコンテキスト
    @MainActor
    func deleteFavoriteSpot(_ spot: FavoriteSpot, context: ModelContext) {
        context.delete(spot)

        do {
            try context.save()
            loadFavoriteSpots(context: context)
            AppLogger.data.info("お気に入りスポットを削除しました: \(spot.name)")
        } catch {
            AppLogger.data.error("お気に入りスポットの削除に失敗: \(error.localizedDescription)")
        }
    }

    /// 指定インデックスのお気に入りスポットを削除する。
    ///
    /// - Parameters:
    ///   - offsets: 削除するインデックス
    ///   - context: SwiftDataのモデルコンテキスト
    @MainActor
    func deleteFavoriteSpots(at offsets: IndexSet, context: ModelContext) {
        for index in offsets {
            let spot = favoriteSpots[index]
            context.delete(spot)
        }

        do {
            try context.save()
            loadFavoriteSpots(context: context)
        } catch {
            AppLogger.data.error("お気に入りスポットの削除に失敗: \(error.localizedDescription)")
        }
    }

    /// プランを選択して詳細を表示する。
    ///
    /// - Parameter plan: 選択するプラン
    func selectPlan(_ plan: SightseeingPlan) {
        selectedPlan = plan
        showPlanDetail = true
    }
}
