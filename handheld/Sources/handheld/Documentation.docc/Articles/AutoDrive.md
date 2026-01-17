# オートドライブ機能

ルートに沿ったLook Aroundプレビュー機能を説明します。

## 概要

オートドライブは、生成されたルートに沿ってLook Aroundシーンを自動再生する機能です。
実際に現地を訪れる前にルートを仮想的に体験できます。

## 機能

- ルートに沿った自動シーン切り替え
- 3段階の再生速度
- 一時停止/再開
- バッファリング中の待機表示

## 再生速度

``AutoDriveSpeed``で3段階の速度を選択できます：

- **遅い** (`.slow`) - 5秒間隔。景色をゆっくり楽しみたい場合
- **普通** (`.normal`) - 3秒間隔。標準的な速度
- **速い** (`.fast`) - 1.5秒間隔。素早くルートを確認したい場合

## 状態遷移

``AutoDriveState``で再生状態を管理します：

```
idle → initializing → loading → playing ⇄ paused
                                  ↓
                              buffering
                                  ↓
                              completed
```

### 各状態の説明

- **idle** - 待機状態。オートドライブ未開始
- **initializing** - 初期化中。最初のシーンを取得中
- **loading** - 読み込み中。シーンを先読み取得中
- **playing** - 再生中
- **paused** - 一時停止中
- **buffering** - バッファリング中。次のシーンを待機
- **completed** - 完了。ルートの終点に到達
- **failed** - 失敗。エラーが発生

## シーン取得戦略

``AutoDriveServiceProtocol``は効率的なシーン取得を行います：

### 1. ドライブポイント抽出

ルートのポリラインから等間隔（デフォルト30m）でポイントを抽出。

```swift
let points = service.extractDrivePoints(from: polyline, interval: 30)
```

### 2. 初期シーン並列取得

再生開始前に最初の数件を並列で取得し、スムーズな再生開始を実現。

```swift
let successCount = await service.fetchInitialScenes(
    for: points,
    initialCount: 3
) { index, scene in
    // シーン取得完了時の処理
}
```

### 3. 先読み取得

再生中に先のシーンを順次取得。レート制限を考慮して100ms間隔で取得。

## キャッシュ

``LookAroundServiceProtocol``はキャッシュを活用します：

- メモリキャッシュ - 取得済みシーンを再利用
- 利用不可キャッシュ - Look Around非対応の座標をスキップ

## 設定

``AutoDriveConfiguration``で設定を管理：

```swift
var config = AutoDriveConfiguration()
config.speed = .fast

// 設定値
config.initialFetchCount  // 初期取得件数（3）
config.prefetchLookahead  // 先読み件数（5）
```

## 関連項目

- ``AutoDriveServiceProtocol``
- ``AutoDriveSpeed``
- ``AutoDriveState``
- ``AutoDriveConfiguration``
- <doc:Architecture>
