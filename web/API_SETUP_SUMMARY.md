# API セットアップ完了サマリー

## 📋 作成されたファイル一覧

### 1. API仕様書・ドキュメント

| ファイル | 説明 | 用途 |
|---------|------|------|
| `openapi.yaml` | OpenAPI 3.0 仕様書 | API仕様の標準定義、ツールとの連携 |
| `API_DOCUMENTATION.md` | 詳細なAPIドキュメント | 全エンドポイントの使い方と例 |
| `QUICKSTART.md` | クイックスタートガイド | 5分で始めるための手順 |
| `public/openapi.yaml` | OpenAPI仕様書（公開用） | ブラウザからアクセス可能 |
| `public/api-docs.html` | Swagger UI | インタラクティブなAPIドキュメント |

### 2. TypeScript SDK

| ファイル | 説明 | 用途 |
|---------|------|------|
| `src/api-client/index.ts` | TypeScript APIクライアント | 型安全なAPI呼び出し |
| `src/api-client/README.md` | SDKドキュメント | SDKの使い方と例 |

### 3. 更新されたファイル

| ファイル | 変更内容 |
|---------|---------|
| `README.md` | API仕様書とSDKへのリンク追加、環境変数の説明を拡充 |

---

## 🎯 主な機能

### 実装されているAPI

1. **AI テキスト生成**
   - `POST /api/qwen` - Qwen AIによるテキスト生成
   - `POST /api/gemini` - Gemini AIによるテキスト生成

2. **Places & Routes**
   - `POST /api/places/geocode` - 住所のジオコーディング
   - `POST /api/routes/optimize` - ルート最適化

3. **パイプライン（E2E）**
   - `POST /api/pipeline/route-optimize` - AIルート最適化パイプライン

4. **シナリオ生成**
   - `POST /api/route/generate` - AIによるルート自動生成
   - `POST /api/scenario` - タクシーシナリオ生成
   - `POST /api/scenario/spot` - 単一地点シナリオ生成
   - `POST /api/scenario/integrate` - シナリオ統合

---

## 🚀 使い方

### 1. ドキュメントを読む

**初めての方:**
```
web/QUICKSTART.md
```
5分でAPIの基本的な使い方を学べます。

**詳しく知りたい方:**
```
web/API_DOCUMENTATION.md
```
全エンドポイントの詳細な説明と使用例が記載されています。

**OpenAPI仕様書:**
```
web/openapi.yaml
```
標準的なOpenAPI 3.0形式で、各種ツールと連携可能です。

### 2. Swagger UIを使う

開発サーバーを起動:
```bash
npm run dev
```

ブラウザで以下にアクセス:
```
http://localhost:3000/api-docs.html
```

Swagger UIで:
- 全エンドポイントを確認
- リクエスト/レスポンスの型を確認
- 「Try it out」ボタンで直接APIを試せる

### 3. TypeScript SDKを使う

**インストール不要** - プロジェクトに含まれています。

```typescript
import { apiClient } from '@/api-client';

// AIルート最適化パイプライン
const result = await apiClient.pipelineRouteOptimize({
  startPoint: '東京駅',
  purpose: '皇居周辺の観光スポットを巡りたい',
  spotCount: 5,
  model: 'gemini'
});

if (result.success) {
  console.log('ルート名:', result.routeGeneration.routeName);
  console.log('総距離:', apiClient.formatDistance(
    result.routeOptimization.totalDistanceMeters!
  ));
}
```

詳細は `src/api-client/README.md` を参照。

### 4. REST APIとして直接呼び出す

**cURL:**
```bash
curl -X POST http://localhost:3000/api/pipeline/route-optimize \
  -H "Content-Type: application/json" \
  -d '{
    "startPoint": "東京駅",
    "purpose": "皇居周辺の観光スポットを巡りたい",
    "spotCount": 5,
    "model": "gemini"
  }'
```

**fetch:**
```javascript
const response = await fetch('/api/pipeline/route-optimize', {
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
```

---

## 🔧 環境変数の設定

### 必須

```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### AI APIキー（使用するモデルに応じて）

```env
QWEN_API_KEY=your_qwen_api_key
GEMINI_API_KEY=your_gemini_api_key
```

### オプション

```env
QWEN_REGION=international  # または 'china'
```

---

## 📊 APIの入出力形式

### すべて JSON 形式

**リクエスト:**
```json
{
  "startPoint": "東京駅",
  "purpose": "皇居周辺の観光スポットを巡りたい",
  "spotCount": 5,
  "model": "gemini"
}
```

**レスポンス:**
```json
{
  "success": true,
  "routeGeneration": {
    "status": "completed",
    "routeName": "皇居周辺歴史巡りツアー",
    "spots": [...]
  },
  "geocoding": {...},
  "routeOptimization": {...},
  "totalProcessingTimeMs": 4500
}
```

### TypeScript 型定義

すべてのリクエスト・レスポンスに型定義があります:
- `src/types/place-route.ts`
- `src/types/pipeline.ts`
- `src/types/api.ts`
- `src/types/scenario.ts`
- `src/types/route.ts`

---

## 🛠️ OpenAPI仕様書の活用

### Postmanでインポート

1. Postmanを開く
2. Import → Upload Files
3. `web/openapi.yaml` を選択
4. すべてのエンドポイントがコレクションとして追加される

### VS Codeで補完

OpenAPI拡張機能をインストール:
```
ext install 42Crunch.vscode-openapi
```

`openapi.yaml` を開くと、スキーマ検証と補完が有効になります。

### コード生成

OpenAPI Generator を使用して各言語のクライアントを自動生成:

```bash
# Python クライアント生成
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g python \
  -o ./clients/python

# Java クライアント生成
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g java \
  -o ./clients/java
```

---

## 🌐 本番環境へのデプロイ

### 環境変数の設定

Vercel、Netlify、AWS などにデプロイする際は、環境変数を設定:

```
GOOGLE_MAPS_API_KEY=***
GEMINI_API_KEY=***
QWEN_API_KEY=***
```

### ベースURLの変更

TypeScript SDKを使用する場合、本番環境のURLを指定:

```typescript
import { TaxiScenarioApiClient } from '@/api-client';

const client = new TaxiScenarioApiClient({
  baseUrl: 'https://api.example.com'
});
```

---

## 📖 ドキュメント構成

```
web/
├── README.md                    # プロジェクト概要
├── QUICKSTART.md               # クイックスタートガイド ⚡
├── API_DOCUMENTATION.md        # 詳細APIドキュメント 📚
├── openapi.yaml                # OpenAPI 3.0仕様書 📋
├── API_SETUP_SUMMARY.md        # このファイル 📝
│
├── src/api-client/
│   ├── index.ts                # TypeScript SDKクライアント
│   └── README.md               # SDKドキュメント
│
└── public/
    ├── openapi.yaml            # OpenAPI仕様書（公開用）
    └── api-docs.html           # Swagger UI
```

---

## ✅ チェックリスト

APIを使い始める前に:

- [ ] 環境変数を設定した（`.env`ファイル）
- [ ] 開発サーバーを起動した（`npm run dev`）
- [ ] Swagger UIにアクセスできた（http://localhost:3000/api-docs.html）
- [ ] APIドキュメントを読んだ（`API_DOCUMENTATION.md`）
- [ ] TypeScript SDKの使い方を確認した（`src/api-client/README.md`）

---

## 🎓 学習パス

### 初級者向け

1. `QUICKSTART.md` を読む
2. Swagger UIで各エンドポイントを試す
3. UIから実際にAPIを呼び出してみる（http://localhost:3000）

### 中級者向け

1. `API_DOCUMENTATION.md` で全エンドポイントを理解
2. TypeScript SDKを使ってコードから呼び出す
3. 各APIを組み合わせて複雑なフローを実装

### 上級者向け

1. `openapi.yaml` で詳細な仕様を確認
2. カスタムクライアントを実装
3. OpenAPI Generatorで他言語のクライアントを生成

---

## 🔗 便利なリンク

### 開発サーバー起動後にアクセス可能

- **Web UI**: http://localhost:3000
- **Swagger UI**: http://localhost:3000/api-docs.html
- **OpenAPI仕様書**: http://localhost:3000/openapi.yaml

### ドキュメント

- [クイックスタート](./QUICKSTART.md)
- [APIドキュメント](./API_DOCUMENTATION.md)
- [TypeScript SDK](./src/api-client/README.md)

---

## 🆘 トラブルシューティング

### エラー: "GOOGLE_MAPS_API_KEYが設定されていません"

→ `.env` ファイルに `GOOGLE_MAPS_API_KEY` を設定してください。

### エラー: "リクエストがタイムアウトしました"

→ SDKのタイムアウト設定を延長:
```typescript
const client = new TaxiScenarioApiClient({ timeout: 60000 });
```

### Swagger UIが表示されない

→ `public/openapi.yaml` が存在するか確認。なければ:
```bash
cp openapi.yaml public/openapi.yaml
```

---

## 📝 次のステップ

1. ✅ ドキュメントを確認
2. ✅ APIを試す
3. ✅ 自分のアプリケーションに統合
4. 📊 フィードバックを共有

Happy Coding! 🚀
