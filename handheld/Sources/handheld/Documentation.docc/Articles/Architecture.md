# アーキテクチャ

handheldアプリのアーキテクチャ設計について説明します。

## 概要

本アプリはMVVM（Model-View-ViewModel）アーキテクチャを採用しています。
Observationフレームワークの`@Observable`マクロを使用し、リアクティブなデータバインディングを実現しています。

## レイヤー構成

### Model層

SwiftDataを使用したデータ永続化層です。

- ``SightseeingPlan`` - 観光プランを表すモデル
- ``PlanSpot`` - プラン内の個別スポット
- ``FavoriteSpot`` - お気に入りスポット

### Service層

ビジネスロジックとAPI呼び出しを担当します。
プロトコル駆動設計により、テスト容易性を確保しています。

**プラン生成:**
- ``PlanGeneratorServiceProtocol`` - AIプラン生成
- ``SpotSearchServiceProtocol`` - スポット検索

**地図・ナビゲーション:**
- ``AutoDriveServiceProtocol`` - オートドライブ
- ``LookAroundServiceProtocol`` - Look Aroundシーン取得
- ``LocationManager`` - 位置情報管理

### ViewModel層

ViewとModelを橋渡しするレイヤーです。

- ``PlanGeneratorViewModel`` - プラン生成画面の状態管理
- ``ContentViewModel`` - メイン画面の状態管理
- ``FavoritesViewModel`` - お気に入り画面の状態管理

### View層

SwiftUIで構築されたUI層です。

## データフロー

```
User Action → ViewModel → Service → Model
                ↓
            View Update
```

1. ユーザーがViewを操作
2. ViewModelがServiceを呼び出し
3. Serviceがデータを取得/変換
4. Modelが更新
5. `@Observable`によりViewが自動更新

## 依存性注入

サービス層はプロトコルを介して注入され、テスト時にモックに差し替え可能です。

```swift
final class PlanGeneratorViewModel {
    init(
        planGeneratorService: PlanGeneratorServiceProtocol = PlanGeneratorService(),
        spotSearchService: SpotSearchServiceProtocol = SpotSearchService()
    )
}
```

## 関連項目

- <doc:GettingStarted>
- <doc:PlanGeneration>
- <doc:AutoDrive>
