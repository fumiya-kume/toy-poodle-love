import Foundation
import Observation
import SwiftData
import os

enum FavoritesTab: String, CaseIterable, Identifiable {
    case plans = "プラン"
    case spots = "スポット"

    var id: String { rawValue }
}

@Observable
final class FavoritesViewModel {
    var selectedTab: FavoritesTab = .plans
    var plans: [SightseeingPlan] = []
    var favoriteSpots: [FavoriteSpot] = []
    var selectedPlan: SightseeingPlan?
    var showPlanDetail: Bool = false

    var isEmpty: Bool {
        switch selectedTab {
        case .plans:
            return plans.isEmpty
        case .spots:
            return favoriteSpots.isEmpty
        }
    }

    var emptyMessage: String {
        switch selectedTab {
        case .plans:
            return "保存したプランがありません"
        case .spots:
            return "お気に入りスポットがありません"
        }
    }

    var emptyIcon: String {
        switch selectedTab {
        case .plans:
            return "map"
        case .spots:
            return "heart"
        }
    }

    @MainActor
    func loadData(context: ModelContext) {
        loadPlans(context: context)
        loadFavoriteSpots(context: context)
    }

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

    func selectPlan(_ plan: SightseeingPlan) {
        selectedPlan = plan
        showPlanDetail = true
    }
}
