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
  - テキスト専用: `qwen-turbo`モデル
  - Vision-Language対応: `qwen3-vl-flash`モデル (画像がある場合に自動切り替え)
  - リージョン選択可能(中国 vs 国際)
  - ベースURLが異なるため、regionパラメータで切り替え
  - 画像はbase64エンコードまたはURLで送信可能

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

4. **自動モデル選択**:
   - 地点情報に画像URLが含まれる場合、`models`が`qwen`/`qwen-vl`/`both`のいずれかであれば、QwenはVision-Languageモデル(`qwen3-vl-flash`)を自動使用
   - `models=gemini`では画像は無視される(Geminiは画像非対応)
   - `QWEN_API_KEY`が未設定の場合はVLモデルは使用不可
   - 画像がない場合は通常のテキストモデル(`qwen-turbo`)を使用
   - この切り替えは`generator.ts`で透過的に処理される

## Vision-Language機能

### 画像入力サポート

- 各地点に画像を追加可能(オプション)
- 画像がある場合、Qwen VLモデルが自動的に使用され、画像の視覚的特徴を含めたシナリオを生成
- 画像はブラウザでbase64エンコードされてAPIに送信(最大5MB: 元ファイルサイズ基準)
- サポート形式: JPEG, PNG, WebP など主要な画像形式
- **注意**: Geminiは画像処理に対応していないため、`models=gemini`では画像は無視されます

### モデル選択ロジック

```typescript
// generator.ts内での自動切り替え
const useQwenVL = spot.imageUrl && this.qwenClient;
if (useQwenVL) {
  await this.qwenClient.chatWithImage(prompt, spot.imageUrl);
} else {
  await this.qwenClient.chat(prompt);
}
```

## コード変更時の注意点

- APIクライアント(`src/`)を変更する場合、CLIとWeb両方の動作を確認
- 新しいモデルパラメータを追加する場合、両方のクライアントで整合性を保つ
- API Routesは各クライアントの薄いラッパーとして保つ
- tsconfig.jsonのパスエイリアス`@/*`は現在ルート相対パスを指す
- 画像機能はQwenのみ対応(Geminiは現在テキスト専用)
