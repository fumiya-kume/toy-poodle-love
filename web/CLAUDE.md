# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Taxi Scenario Writerは、QwenとGemini APIを呼び出す最小限のTypeScriptアプリケーションです。CLIとNext.js Webインターフェースの両方を提供します。

## 必須のセットアップ

環境変数の設定が必須です:
```bash
cp .env.example .env
```

`.env`ファイルに以下の2つのAPIキーを設定してください:
- `QWEN_API_KEY`: Alibaba Cloud DashScopeから取得
- `GEMINI_API_KEY`: Google AI Studioから取得
- `QWEN_REGION` (オプション): `china` または `international` (デフォルト: `international`)

## 開発コマンド

```bash
# Next.js開発サーバー起動
npm run dev

# プロダクションビルド
npm run build

# プロダクションサーバー起動
npm start

# リント
npm run lint

# CLIモードで実行(両方のAPIをテスト)
npm run cli
```

**重要**: `npm run dev`および`npm start`は長時間実行されるサーバープロセスのため、Claude Codeが自動的に実行してはいけません。ユーザーが明示的に要求した場合のみ実行してください。

## アーキテクチャ

### デュアルモード構成

このアプリケーションは2つのモードで動作します:

1. **CLIモード** (`src/index.ts`)
   - `npm run cli`で起動
   - 両方のAPIクライアントを順次呼び出してテスト
   - dotenvで環境変数を読み込み

2. **Webモード** (Next.js App Router)
   - `npm run dev`で起動
   - ユーザーがモデルを選択して並列で呼び出し可能
   - API RoutesがAPIクライアントをラップ

### コアコンポーネント

#### APIクライアント (`src/`)

- **`qwen-client.ts`**: OpenAI互換のDashScope APIを使用
  - OpenAI SDKを利用して`qwen-plus`モデルを呼び出し
  - リージョン選択可能(中国 vs 国際)
  - ベースURLが異なるため、regionパラメータで切り替え

- **`gemini-client.ts`**: Google Generative AI SDKを使用
  - `gemini-2.5-flash-lite`モデルを使用
  - 直接的なGoogle AI SDKの実装

#### Next.js レイヤー (`app/`)

- **API Routes** (`app/api/*/route.ts`)
  - 各モデルごとに個別のエンドポイント(`/api/qwen`, `/api/gemini`)
  - APIクライアントクラスをインスタンス化して呼び出し
  - エラーハンドリングとレスポンスの標準化

- **UI** (`app/page.tsx`)
  - Reactフォームで複数モデル選択可能
  - `Promise.all`で並列API呼び出し
  - インラインスタイルでシンプルなUI

### 重要な設計パターン

1. **クライアントクラスの再利用**: `src/`のクライアントクラスがCLIとWeb両方で共有される

2. **環境変数の分離**:
   - CLI: `dotenv`で`.env`を明示的にロード
   - Web: Next.jsが自動的に`.env`を読み込み

3. **並列処理**: Web UIでは有効なモデルのAPIコールを`Promise.all`で並列実行

## コード変更時の注意点

- APIクライアント(`src/`)を変更する場合、CLIとWeb両方の動作を確認
- 新しいモデルパラメータを追加する場合、両方のクライアントで整合性を保つ
- API Routesは各クライアントの薄いラッパーとして保つ
- tsconfig.jsonのパスエイリアス`@/*`は現在ルート相対パスを指す
