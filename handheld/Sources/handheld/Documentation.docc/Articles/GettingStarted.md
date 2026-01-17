# はじめに

handheldアプリの概要と基本的な使い方を説明します。

## 概要

handheldは、観光プランを簡単に作成できるiOSアプリです。
Apple Intelligenceを活用したAIプラン生成と、Look Aroundによるルートプレビューが特徴です。

## 主な機能

### プラン生成

1. エリアを選択
2. カテゴリを選択（景勝地、アクティビティ、ショッピング）
3. テーマを入力
4. AIがプランを自動生成

``PlanGeneratorViewModel``がプラン生成のフローを管理します。

### オートドライブ

生成されたルートをLook Aroundでプレビューできます。
再生速度は3段階（遅い、普通、速い）から選択可能です。

``AutoDriveService``がシーンの取得と再生を管理します。

### お気に入り管理

- プランの保存・削除
- スポットのお気に入り登録

``FavoritesViewModel``でお気に入りを管理します。

## 必要条件

- iOS 17.0以上
- AI生成機能にはiOS 26.0以上とApple Intelligence対応デバイスが必要

## 関連項目

- <doc:Architecture>
- <doc:PlanGeneration>
- <doc:AutoDrive>
