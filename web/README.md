# Taxi Scenario Writer

タクシールート最適化とシナリオ生成を行うTypeScriptアプリケーション

## 📚 ドキュメント

- **[クイックスタート](./QUICKSTART.md)** - 5分で始めるガイド ⚡
- **[API仕様書（OpenAPI）](./openapi.yaml)** - 完全なOpenAPI 3.0仕様書
- **[APIドキュメント](./API_DOCUMENTATION.md)** - 詳細なAPIドキュメントと使用例
- **[TypeScript SDK](./src/api-client/README.md)** - TypeScriptクライアントライブラリの使い方
- **[Swagger UI](http://localhost:3000/api-docs.html)** - インタラクティブなAPIドキュメント（開発サーバー起動後）

## セットアップ

### 1. 依存関係のインストール

```bash
npm install
```

### 2. 環境変数の設定

`.env.example`ファイルを`.env`にコピーして、APIキーを設定します。

```bash
cp .env.example .env
```

`.env`ファイルを編集して、以下のAPIキーを設定してください:

```env
# 必須
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# AI APIキー（使用するモデルに応じて）
QWEN_API_KEY=your_qwen_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here

# オプション
QWEN_REGION=international  # または 'china'
```

### APIキーの取得方法

#### Google Maps API Key（必須）
1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクトを作成または選択
3. 以下のAPIを有効化:
   - Places API (New)
   - Routes API
4. 認証情報からAPIキーを作成

#### Qwen API Key
1. [Alibaba Cloud DashScope](https://dashscope.console.aliyun.com/)にアクセス
2. アカウントを作成してログイン
3. APIキーを生成

#### Gemini API Key
1. [Google AI Studio](https://makersuite.google.com/app/apikey)にアクセス
2. Googleアカウントでログイン
3. "Get API Key"をクリックしてキーを生成

## 主な機能

- **AI テキスト生成**: Qwen / Gemini モデルを使用したテキスト生成
- **ジオコーディング**: 住所から緯度経度を取得
- **ルート最適化**: 複数地点を含む最適なルートを計算
- **AI ルート生成**: テーマに基づいて訪問スポットを自動生成
- **シナリオ生成**: タクシーガイド用のシナリオテキストを生成
- **E2E パイプライン**: ルート生成→ジオコーディング→最適化を一括実行

## 使い方

### 開発モードで実行

```bash
npm run dev
```

ブラウザで http://localhost:3000 にアクセスしてUIを使用できます。

### ビルドして実行

```bash
npm run build
npm start
```

## API の使い方

### REST API として使用

APIエンドポイントに直接HTTPリクエストを送信できます。詳細は [APIドキュメント](./API_DOCUMENTATION.md) を参照してください。

```typescript
// 例: AI ルート最適化パイプライン
const response = await fetch('http://localhost:3000/api/pipeline/route-optimize', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    startPoint: '東京駅',
    purpose: '皇居周辺の観光スポットを巡りたい',
    spotCount: 5,
    model: 'gemini'
  })
});

const data = await response.json();
console.log(data);
```

### TypeScript SDK を使用

TypeScriptクライアントライブラリを使用すると、型安全にAPIを呼び出せます。詳細は [TypeScript SDK ドキュメント](./src/api-client/README.md) を参照してください。

```typescript
import { apiClient } from '@/api-client';

// AI ルート最適化パイプライン
const result = await apiClient.pipelineRouteOptimize({
  startPoint: '東京駅',
  purpose: '皇居周辺の観光スポットを巡りたい',
  spotCount: 5,
  model: 'gemini'
});

if (result.success) {
  console.log('ルート名:', result.routeGeneration.routeName);
  console.log('総距離:', apiClient.formatDistance(result.routeOptimization.totalDistanceMeters!));
}
```

## プロジェクト構成

```
taxi-senario-writer/
├── src/
│   ├── index.ts           # メインアプリケーション
│   ├── qwen-client.ts     # Qwen APIクライアント
│   └── gemini-client.ts   # Gemini APIクライアント
├── package.json
├── tsconfig.json
├── .env.example
├── .gitignore
└── README.md
```

## 利用可能なAPIエンドポイント

### AI テキスト生成
- `POST /api/qwen` - Qwen AI によるテキスト生成
- `POST /api/gemini` - Gemini AI によるテキスト生成

### Places & Routes
- `POST /api/places/geocode` - 住所のジオコーディング
- `POST /api/routes/optimize` - ルート最適化

### パイプライン（E2E）
- `POST /api/pipeline/route-optimize` - AI ルート最適化パイプライン

### シナリオ生成
- `POST /api/route/generate` - AI によるルート自動生成
- `POST /api/scenario` - タクシーシナリオ生成
- `POST /api/scenario/spot` - 単一地点シナリオ生成
- `POST /api/scenario/integrate` - シナリオ統合

詳細は [APIドキュメント](./API_DOCUMENTATION.md) を参照してください。

## 使用しているモデル

- **Qwen**: `qwen-turbo` (他のオプション: `qwen-flash`, `qwen-max`, `qwen-plus`)
- **Gemini**: `gemini-2.5-flash-lite` (他のオプション: `gemini-1.5-pro`)
- **Google Maps**: Places API (New), Routes API

## ライセンス

ISC
