# プラン生成フロー

観光プランがどのように生成されるかを説明します。

## 概要

プラン生成は以下の4つの処理段階を経て完了します：

1. スポット検索
2. AI生成
3. マッチング
4. ルート計算

## ウィザードステップ

``PlanGeneratorStep``で定義される4ステップでユーザー入力を収集します：

1. **エリア選択** (`.location`) - 検索中心地を指定
2. **カテゴリ選択** (`.category`) - ``PlanCategory``から選択
3. **テーマ設定** (`.theme`) - プランのテーマを入力
4. **確認** (`.confirm`) - 設定を確認して生成開始

## 処理の詳細

### 1. スポット検索

``SpotSearchServiceProtocol``がテーマとカテゴリに基づいて周辺のスポットを検索します。

- 複数のキーワードで並列検索
- 検索範囲内の結果のみ抽出
- 重複を除去

### 2. AI生成

``PlanGeneratorServiceProtocol``がApple Intelligenceを使用し、候補スポットから最適な訪問順序を決定します。

- iOS 26.0以上が必要
- FoundationModelsフレームワークを使用
- 3〜9スポットを選択

### 3. マッチング

AI生成結果のスポット名と実際の場所をマッチングします。

```swift
let matchedSpots = service.matchGeneratedSpotsWithPlaces(
    generatedSpots: generated.spots,
    candidatePlaces: candidatePlaces
)
```

マッチング方法：
1. 完全一致
2. 正規化後の一致
3. ファジーマッチング（類似度70%以上）

### 4. ルート計算

スポット間のルートを計算し、移動距離と時間を算出します。

## 状態管理

``PlanGeneratorState``で生成の進捗を管理します：

- `.idle` - 待機中
- `.searchingSpots` - スポット検索中
- `.generatingPlan` - AI生成中
- `.calculatingRoutes` - ルート計算中
- `.completed` - 完了
- `.error(message:)` - エラー発生

## 関連項目

- ``PlanGeneratorViewModel``
- ``PlanGeneratorServiceProtocol``
- ``SpotSearchServiceProtocol``
- <doc:Architecture>
