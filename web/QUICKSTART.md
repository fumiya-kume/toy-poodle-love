# クイックスタートガイド

Taxi Scenario Writer API を5分で始める方法

## 1. セットアップ（2分）

### 環境変数を設定

```bash
cd web
cp .env.example .env
```

`.env` ファイルに必要なAPIキーを設定:

```env
# 必須
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# AI APIキー（どちらか一方でOK）
GEMINI_API_KEY=your_gemini_api_key
# または
QWEN_API_KEY=your_qwen_api_key
```

### 依存関係をインストール

```bash
npm install
```

### サーバーを起動

```bash
npm run dev
```

## 2. ブラウザでテスト（1分）

### UIを使う

ブラウザで http://localhost:3000 にアクセス

「AI ルート最適化」タブで:
- 出発地点: `東京駅`
- 目的・テーマ: `皇居周辺の観光スポットを巡りたい`
- 地点数: `5`
- AIモデル: `Gemini`

「AI でルートを生成・最適化」ボタンをクリック

### API ドキュメントを見る

ブラウザで http://localhost:3000/api-docs.html にアクセス

Swagger UI でインタラクティブにAPIを試せます。

## 3. コードで呼び出す（2分）

### TypeScript SDK を使う

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
  console.log('スポット:', result.routeGeneration.spots);
  console.log('総距離:', apiClient.formatDistance(
    result.routeOptimization.totalDistanceMeters!
  ));
  console.log('総時間:', apiClient.formatDuration(
    result.routeOptimization.totalDurationSeconds!
  ));
}
```

### cURL で呼び出す

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

### fetch で呼び出す

```javascript
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

## 次のステップ

### より詳しく学ぶ

- **[API仕様書](./openapi.yaml)** - 完全なOpenAPI 3.0仕様書
- **[APIドキュメント](./API_DOCUMENTATION.md)** - 全エンドポイントの詳細
- **[TypeScript SDK](./src/api-client/README.md)** - SDKの使い方

### 他のAPIも試す

#### 1. 手動でルートを最適化

```typescript
// Step 1: ジオコーディング
const geocodeRes = await apiClient.geocode({
  addresses: ['東京駅', '浅草寺', '東京スカイツリー', '上野公園']
});

// Step 2: ルート最適化
const places = geocodeRes.places!;
const optimizeRes = await apiClient.optimizeRoute({
  origin: { placeId: places[0].placeId, name: places[0].inputAddress },
  destination: { placeId: places[3].placeId, name: places[3].inputAddress },
  intermediates: [
    { placeId: places[1].placeId, name: places[1].inputAddress },
    { placeId: places[2].placeId, name: places[2].inputAddress }
  ],
  travelMode: 'DRIVE',
  optimizeWaypointOrder: true
});

console.log('最適ルート:', optimizeRes.optimizedRoute);
```

#### 2. AI にテキスト生成させる

```typescript
// Gemini
const geminiRes = await apiClient.geminiChat('東京の観光スポットを3つ教えて');
console.log(geminiRes);

// Qwen
const qwenRes = await apiClient.qwenChat('東京の観光スポットを3つ教えて');
console.log(qwenRes);
```

#### 3. シナリオを生成する

```typescript
// Step 1: ルート生成
const routeRes = await apiClient.generateRoute({
  input: {
    startPoint: '東京駅',
    purpose: '皇居周辺を観光したい',
    spotCount: 5,
    model: 'gemini'
  }
});

// Step 2: シナリオ生成
const scenarioRes = await apiClient.generateScenario({
  route: {
    routeName: routeRes.data!.routeName,
    spots: routeRes.data!.spots
  },
  models: 'both'
});

// Step 3: シナリオ統合
const integrationRes = await apiClient.integrateScenario({
  integration: {
    routeName: scenarioRes.data!.routeName,
    spots: scenarioRes.data!.spots,
    sourceModel: 'gemini'
  }
});

console.log('統合シナリオ:', integrationRes.data!.integratedScript);
```

## トラブルシューティング

### APIキーが設定されていないエラー

```json
{
  "error": "GOOGLE_MAPS_API_KEYが設定されていません"
}
```

→ `.env` ファイルに正しいAPIキーが設定されているか確認してください。

### タイムアウトエラー

```json
{
  "error": "リクエストがタイムアウトしました"
}
```

→ デフォルトのタイムアウトは30秒です。`TaxiScenarioApiClient` の初期化時に `timeout` オプションで変更できます:

```typescript
const client = new TaxiScenarioApiClient({
  timeout: 60000  // 60秒
});
```

### ジオコーディングが失敗する

```json
{
  "success": false,
  "error": "有効な地点が2つ以上見つかりませんでした"
}
```

→ 住所や場所名をより具体的に指定してください（例: "東京駅" → "東京都千代田区丸の内1丁目"）

## サポート

問題が発生した場合は:
1. [APIドキュメント](./API_DOCUMENTATION.md)を確認
2. [GitHub Issues](https://github.com/your-repo/issues)で報告

## 便利なリンク

- **Swagger UI**: http://localhost:3000/api-docs.html
- **Web UI**: http://localhost:3000
- **OpenAPI仕様書**: http://localhost:3000/openapi.yaml
