# ``handheld``

観光プランを簡単に作成・ナビゲートできるiOSアプリです。

@Metadata {
    @DisplayName("handheld - 観光プランナー")
    @PageColor(blue)
}

## 概要

handheldは、周辺の観光スポットを発見し、最適な観光ルートを計画し、
Apple Look AroundプレビューでナビゲートするためのiOSアプリケーションです。

SwiftUIとMapKitで構築されており、旅行者が新しい場所を探索する際に
時間を最大限に活用できるシームレスな体験を提供します。

### 主な機能

- **AIプラン生成**: Apple Intelligenceを活用した観光プランの自動生成
- **オートドライブ**: Look Aroundによるルートプレビュー機能
- **お気に入り管理**: 気になるスポットを保存

### 必要条件

- iOS 17.0以上
- AI生成機能にはiOS 26.0以上とApple Intelligence対応デバイスが必要

## Topics

### はじめに

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:PlanGeneration>
- <doc:AutoDrive>

### コアモデル

- ``SightseeingPlan``
- ``PlanSpot``
- ``FavoriteSpot``

### 列挙型

- ``PlanCategory``
- ``SearchRadius``
- ``AutoDriveSpeed``
- ``AutoDriveState``
- ``AppError``

### サービス

- ``PlanGeneratorServiceProtocol``
- ``PlanGeneratorService``
- ``AutoDriveServiceProtocol``
- ``AutoDriveService``
- ``SpotSearchServiceProtocol``
- ``SpotSearchService``
- ``LocationManager``
- ``LookAroundServiceProtocol``
- ``LookAroundService``

### ViewModel

- ``PlanGeneratorViewModel``
- ``ContentViewModel``
- ``FavoritesViewModel``
