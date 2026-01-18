# Taxi Scenario Writer API ドキュメント

## 概要

Taxi Scenario Writer は、タクシールート最適化とシナリオ生成を行うAPIです。

**主な機能:**
- AI テキスト生成（Qwen / Gemini）
- 住所のジオコーディング（Google Places API）
- ルート最適化（Google Routes API）
- AI によるルート自動生成とシナリオ作成

---

## セットアップ

### 必須環境変数

```bash
# 必須
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# AI APIキー（使用するモデルに応じて）
QWEN_API_KEY=your_qwen_api_key
GEMINI_API_KEY=your_gemini_api_key

# オプション
QWEN_REGION=international  # または 'china'
```

### 開発サーバー起動

```bash
npm run dev
```

サーバーは `http://localhost:3000` で起動します。

---

## API エンドポイント一覧

### 1. AI テキスト生成

#### 1.1 Qwen AI テキスト生成

**エンドポイント:** `POST /api/qwen`

**説明:** Alibaba Cloud の Qwen モデルを使用してテキストを生成します。

**リクエスト:**
```json
{
  "message": "東京の観光スポットを3つ教えてください"
}
```

**レスポンス:**
```json
{
  "response": "東京の人気観光スポット3つをご紹介します..."
}
```

**エラーレスポンス:**
```json
{
  "error": "QWEN_API_KEYが設定されていません"
}
```

**TypeScript 呼び出し例:**
```typescript
const response = await fetch('/api/qwen', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: '東京の観光スポットを3つ教えてください'
  })
});

const data = await response.json();
console.log(data.response);
```

---

#### 1.2 Gemini AI テキスト生成

**エンドポイント:** `POST /api/gemini`

**説明:** Google の Gemini モデルを使用してテキストを生成します。

**リクエスト:**
```json
{
  "message": "東京の観光スポットを3つ教えてください"
}
```

**レスポンス:**
```json
{
  "response": "東京には多くの魅力的な観光スポットがあります..."
}
```

**TypeScript 呼び出し例:**
```typescript
const response = await fetch('/api/gemini', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: '東京の観光スポットを3つ教えてください'
  })
});

const data = await response.json();
console.log(data.response);
```

---

### 2. Places & Routes API

#### 2.1 住所のジオコーディング

**エンドポイント:** `POST /api/places/geocode`

**説明:** 住所または場所名から緯度経度を取得します（Google Places API 使用）。

**リクエスト:**
```json
{
  "addresses": [
    "東京駅",
    "浅草寺",
    "東京スカイツリー"
  ]
}
```

**レスポンス:**
```json
{
  "success": true,
  "places": [
    {
      "inputAddress": "東京駅",
      "formattedAddress": "日本、〒100-0005 東京都千代田区丸の内１丁目",
      "location": {
        "latitude": 35.681236,
        "longitude": 139.767125
      },
      "placeId": "ChIJC3Cf2PuLGGARZ7KXBYZWe5k"
    },
    {
      "inputAddress": "浅草寺",
      "formattedAddress": "日本、〒111-0032 東京都台東区浅草２丁目３−１",
      "location": {
        "latitude": 35.714764,
        "longitude": 139.796574
      },
      "placeId": "ChIJ8T1GpMGOGGARDYGSgpooDWw"
    }
  ]
}
```

**TypeScript 型定義:**
```typescript
interface GeocodeRequest {
  addresses: string[];
}

interface GeocodedPlace {
  inputAddress: string;
  formattedAddress: string;
  location: {
    latitude: number;
    longitude: number;
  };
  placeId: string;
}

interface GeocodeResponse {
  success: boolean;
  places?: GeocodedPlace[];
  error?: string;
}
```

**TypeScript 呼び出し例:**
```typescript
const response = await fetch('/api/places/geocode', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    addresses: ['東京駅', '浅草寺', '東京スカイツリー']
  })
});

const data: GeocodeResponse = await response.json();

if (data.success) {
  data.places?.forEach(place => {
    console.log(`${place.inputAddress}: ${place.location.latitude}, ${place.location.longitude}`);
  });
}
```

---

#### 2.2 ルート最適化

**エンドポイント:** `POST /api/routes/optimize`

**説明:** 出発地、目的地、経由地点を指定してルートを最適化します（Google Routes API 使用）。経由地点の順序を最適化し、総距離と所要時間を最小化します。

**リクエスト:**
```json
{
  "origin": {
    "placeId": "ChIJC3Cf2PuLGGARZ7KXBYZWe5k",
    "name": "東京駅"
  },
  "destination": {
    "placeId": "ChIJ5SZMmrWLGGAR205kNjohnZU",
    "name": "上野公園"
  },
  "intermediates": [
    {
      "placeId": "ChIJ8T1GpMGOGGARDYGSgpooDWw",
      "name": "浅草寺"
    },
    {
      "placeId": "ChIJN33aMnCNGGARID5p4Dl3_4I",
      "name": "東京スカイツリー"
    }
  ],
  "travelMode": "DRIVE",
  "optimizeWaypointOrder": true
}
```

**レスポンス:**
```json
{
  "success": true,
  "optimizedRoute": {
    "orderedWaypoints": [
      {
        "waypoint": {
          "placeId": "ChIJC3Cf2PuLGGARZ7KXBYZWe5k",
          "name": "東京駅"
        },
        "waypointIndex": 0
      },
      {
        "waypoint": {
          "placeId": "ChIJ8T1GpMGOGGARDYGSgpooDWw",
          "name": "浅草寺"
        },
        "waypointIndex": 1
      },
      {
        "waypoint": {
          "placeId": "ChIJN33aMnCNGGARID5p4Dl3_4I",
          "name": "東京スカイツリー"
        },
        "waypointIndex": 2
      },
      {
        "waypoint": {
          "placeId": "ChIJ5SZMmrWLGGAR205kNohnZU",
          "name": "上野公園"
        },
        "waypointIndex": 3
      }
    ],
    "legs": [
      {
        "distanceMeters": 8500,
        "durationSeconds": 1200
      },
      {
        "distanceMeters": 1500,
        "durationSeconds": 300
      },
      {
        "distanceMeters": 3200,
        "durationSeconds": 600
      }
    ],
    "totalDistanceMeters": 13200,
    "totalDurationSeconds": 2100
  }
}
```

**TypeScript 型定義:**
```typescript
interface RouteWaypoint {
  name?: string;
  placeId?: string;
  location?: { latitude: number; longitude: number };
  address?: string;
}

interface RouteOptimizationRequest {
  origin: RouteWaypoint;
  destination: RouteWaypoint;
  intermediates: RouteWaypoint[];
  travelMode?: 'DRIVE' | 'WALK' | 'BICYCLE' | 'TRANSIT';
  optimizeWaypointOrder?: boolean;
}

interface OptimizedWaypoint {
  waypoint: RouteWaypoint;
  waypointIndex: number;
}

interface RouteLeg {
  distanceMeters: number;
  durationSeconds: number;
}

interface RouteOptimizationResponse {
  success: boolean;
  optimizedRoute?: {
    orderedWaypoints: OptimizedWaypoint[];
    legs: RouteLeg[];
    totalDistanceMeters: number;
    totalDurationSeconds: number;
  };
  error?: string;
}
```

**TypeScript 呼び出し例:**
```typescript
// Step 1: まずジオコーディングでPlace IDを取得
const geocodeRes = await fetch('/api/places/geocode', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    addresses: ['東京駅', '浅草寺', '東京スカイツリー', '上野公園']
  })
});
const geocodeData: GeocodeResponse = await geocodeRes.json();

if (!geocodeData.success || !geocodeData.places) {
  throw new Error('ジオコーディングに失敗しました');
}

// Step 2: ルート最適化を実行
const places = geocodeData.places;
const optimizeRes = await fetch('/api/routes/optimize', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    origin: {
      placeId: places[0].placeId,
      name: places[0].inputAddress
    },
    destination: {
      placeId: places[3].placeId,
      name: places[3].inputAddress
    },
    intermediates: [
      { placeId: places[1].placeId, name: places[1].inputAddress },
      { placeId: places[2].placeId, name: places[2].inputAddress }
    ],
    travelMode: 'DRIVE',
    optimizeWaypointOrder: true
  })
});

const optimizeData: RouteOptimizationResponse = await optimizeRes.json();

if (optimizeData.success && optimizeData.optimizedRoute) {
  const route = optimizeData.optimizedRoute;
  console.log(`総距離: ${route.totalDistanceMeters}m`);
  console.log(`総所要時間: ${route.totalDurationSeconds}秒`);

  route.orderedWaypoints.forEach((wp, i) => {
    console.log(`${i + 1}. ${wp.waypoint.name}`);
  });
}
```

---

### 3. パイプライン API（E2E）

#### 3.1 AI ルート最適化パイプライン

**エンドポイント:** `POST /api/pipeline/route-optimize`

**説明:** AI によるルート生成、ジオコーディング、ルート最適化を一括で実行します。

**実行ステップ:**
1. AI がテーマに基づいて訪問スポットを生成
2. 生成されたスポットの座標を取得（ジオコーディング）
3. 最適なルート順序を計算

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
  "request": {
    "startPoint": "東京駅",
    "purpose": "皇居周辺の観光スポットを巡りたい",
    "spotCount": 5,
    "model": "gemini"
  },
  "routeGeneration": {
    "status": "completed",
    "routeName": "皇居周辺歴史巡りツアー",
    "spots": [
      {
        "name": "東京駅",
        "type": "start",
        "description": "赤レンガ駅舎が美しい東京の玄関口"
      },
      {
        "name": "皇居東御苑",
        "type": "intermediate",
        "description": "旧江戸城の本丸跡地"
      },
      {
        "name": "北の丸公園",
        "type": "intermediate",
        "description": "自然豊かな都会のオアシス"
      },
      {
        "name": "靖国神社",
        "type": "intermediate",
        "description": "歴史的な神社"
      },
      {
        "name": "日比谷公園",
        "type": "destination",
        "description": "日本初の洋風公園"
      }
    ],
    "processingTimeMs": 2500
  },
  "geocoding": {
    "status": "completed",
    "places": [
      {
        "inputAddress": "東京駅",
        "formattedAddress": "日本、〒100-0005 東京都千代田区丸の内１丁目",
        "location": {
          "latitude": 35.681236,
          "longitude": 139.767125
        },
        "placeId": "ChIJC3Cf2PuLGGARZ7KXBYZWe5k"
      }
      // ... 他の地点
    ],
    "processingTimeMs": 1200
  },
  "routeOptimization": {
    "status": "completed",
    "orderedWaypoints": [
      {
        "waypoint": {
          "placeId": "ChIJC3Cf2PuLGGARZ7KXBYZWe5k",
          "name": "東京駅"
        },
        "waypointIndex": 0
      }
      // ... 他のウェイポイント
    ],
    "legs": [
      {
        "distanceMeters": 1500,
        "durationSeconds": 300
      }
      // ... 他の区間
    ],
    "totalDistanceMeters": 8500,
    "totalDurationSeconds": 1800,
    "processingTimeMs": 800
  },
  "totalProcessingTimeMs": 4500
}
```

**TypeScript 型定義:**
```typescript
interface PipelineRequest {
  startPoint: string;
  purpose: string;
  spotCount: number; // 3-8
  model: 'qwen' | 'gemini';
}

type PipelineStepStatus = 'pending' | 'in_progress' | 'completed' | 'failed';

interface GeneratedRouteSpot {
  name: string;
  type: 'start' | 'intermediate' | 'destination';
  description?: string;
}

interface RouteGenerationStepResult {
  status: PipelineStepStatus;
  routeName?: string;
  spots?: GeneratedRouteSpot[];
  processingTimeMs?: number;
  error?: string;
}

interface GeocodingStepResult {
  status: PipelineStepStatus;
  places?: GeocodedPlace[];
  failedSpots?: string[];
  processingTimeMs?: number;
  error?: string;
}

interface RouteOptimizationStepResult {
  status: PipelineStepStatus;
  orderedWaypoints?: OptimizedWaypoint[];
  legs?: RouteLeg[];
  totalDistanceMeters?: number;
  totalDurationSeconds?: number;
  processingTimeMs?: number;
  error?: string;
}

interface PipelineResponse {
  success: boolean;
  request: PipelineRequest;
  routeGeneration: RouteGenerationStepResult;
  geocoding: GeocodingStepResult;
  routeOptimization: RouteOptimizationStepResult;
  totalProcessingTimeMs: number;
  error?: string;
}
```

**TypeScript 呼び出し例:**
```typescript
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

const data: PipelineResponse = await response.json();

if (data.success) {
  // ステップ1: AI生成されたルート名とスポット
  console.log('ルート名:', data.routeGeneration.routeName);
  console.log('スポット:', data.routeGeneration.spots);

  // ステップ2: ジオコーディング結果
  console.log('座標取得:', data.geocoding.places);

  // ステップ3: 最適化されたルート
  console.log('総距離:', data.routeOptimization.totalDistanceMeters, 'm');
  console.log('総時間:', data.routeOptimization.totalDurationSeconds, '秒');
  console.log('最適順序:', data.routeOptimization.orderedWaypoints);

  // 処理時間
  console.log('合計処理時間:', data.totalProcessingTimeMs, 'ms');
}
```

---

### 4. シナリオ生成 API

#### 4.1 ルート自動生成

**エンドポイント:** `POST /api/route/generate`

**説明:** AI が目的とテーマに基づいて訪問スポットのリストを生成します。

**リクエスト:**
```json
{
  "input": {
    "startPoint": "東京駅",
    "purpose": "皇居周辺を観光したい",
    "spotCount": 5,
    "model": "gemini",
    "language": "ja"
  }
}
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "generatedAt": "2026-01-18T10:30:00Z",
    "routeName": "皇居周辺歴史巡りツアー",
    "spots": [
      {
        "name": "東京駅",
        "type": "start",
        "description": "赤レンガ駅舎が美しい東京の玄関口"
      },
      {
        "name": "皇居東御苑",
        "type": "waypoint",
        "description": "旧江戸城の本丸跡地",
        "point": "四季折々の花が楽しめる日本庭園"
      }
    ],
    "model": "gemini",
    "processingTimeMs": 2500
  }
}
```

---

#### 4.2 タクシーシナリオ生成

**エンドポイント:** `POST /api/scenario`

**説明:** ルート情報からタクシーガイドのシナリオを生成します。

**リクエスト:**
```json
{
  "route": {
    "routeName": "皇居周辺観光ツアー",
    "spots": [
      {
        "name": "東京駅",
        "type": "start",
        "description": "赤レンガ駅舎",
        "point": "歴史的建築"
      },
      {
        "name": "皇居東御苑",
        "type": "waypoint",
        "description": "旧江戸城本丸",
        "point": "日本庭園"
      }
    ],
    "language": "ja"
  },
  "models": "both"
}
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "generatedAt": "2026-01-18T10:30:00Z",
    "routeName": "皇居周辺観光ツアー",
    "spots": [
      {
        "name": "東京駅",
        "type": "start",
        "qwen": "ようこそ東京駅へ。この赤レンガの駅舎は...",
        "gemini": "本日は東京駅からスタートします。この美しい建物は..."
      },
      {
        "name": "皇居東御苑",
        "type": "waypoint",
        "qwen": "次は皇居東御苑です。ここは旧江戸城の...",
        "gemini": "皇居東御苑にやってきました。こちらは..."
      }
    ],
    "stats": {
      "totalSpots": 2,
      "successCount": {
        "qwen": 2,
        "gemini": 2
      },
      "processingTimeMs": 8500
    }
  }
}
```

---

#### 4.3 単一地点シナリオ生成

**エンドポイント:** `POST /api/scenario/spot`

**説明:** 特定の観光地点に関するタクシーガイドのセリフを生成します。

**リクエスト:**
```json
{
  "routeName": "皇居周辺観光ツアー",
  "spotName": "皇居東御苑",
  "description": "旧江戸城の本丸跡地",
  "point": "四季折々の花が楽しめる日本庭園",
  "models": "both"
}
```

**レスポンス:**
```json
{
  "success": true,
  "scenario": {
    "qwen": "次は皇居東御苑です。ここは旧江戸城の本丸跡地として...",
    "gemini": "皇居東御苑にやってきました。こちらは四季折々の..."
  }
}
```

---

#### 4.4 シナリオ統合

**エンドポイント:** `POST /api/scenario/integrate`

**説明:** 複数地点のシナリオを統合して一つの連続したストーリーにします。別の LLM を使用してクロスチェックと統合を行います。

**リクエスト:**
```json
{
  "integration": {
    "routeName": "皇居周辺観光ツアー",
    "spots": [
      {
        "name": "東京駅",
        "type": "start",
        "gemini": "本日は東京駅からスタートします..."
      },
      {
        "name": "皇居東御苑",
        "type": "waypoint",
        "gemini": "皇居東御苑にやってきました..."
      }
    ],
    "sourceModel": "gemini",
    "integrationLLM": "qwen"
  }
}
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "integratedAt": "2026-01-18T10:35:00Z",
    "routeName": "皇居周辺観光ツアー",
    "sourceModel": "gemini",
    "integrationLLM": "qwen",
    "integratedScript": "本日は皇居周辺を巡る観光ツアーにようこそ。\n\nまず東京駅から出発します。この赤レンガの駅舎は...\n\n次に向かうのは皇居東御苑です。こちらは旧江戸城の...",
    "processingTimeMs": 3500
  }
}
```

---

## エラーハンドリング

全てのエンドポイントは以下の形式でエラーを返します:

```json
{
  "error": "エラーメッセージ"
}
```

または

```json
{
  "success": false,
  "error": "エラーメッセージ"
}
```

**一般的なエラー:**
- `400 Bad Request`: リクエストパラメータが不正
- `500 Internal Server Error`: サーバー内部エラー、API キー未設定など

---

## 使用例: フルフロー

### 例1: 手動でルートを作成して最適化

```typescript
// Step 1: 訪問したい場所をリストアップ
const addresses = ['東京駅', '浅草寺', '東京スカイツリー', '上野公園'];

// Step 2: ジオコーディング
const geocodeRes = await fetch('/api/places/geocode', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ addresses })
});
const geocodeData = await geocodeRes.json();

// Step 3: ルート最適化
const places = geocodeData.places;
const optimizeRes = await fetch('/api/routes/optimize', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    origin: { placeId: places[0].placeId, name: places[0].inputAddress },
    destination: { placeId: places[places.length - 1].placeId, name: places[places.length - 1].inputAddress },
    intermediates: places.slice(1, -1).map(p => ({ placeId: p.placeId, name: p.inputAddress })),
    travelMode: 'DRIVE',
    optimizeWaypointOrder: true
  })
});
const optimizeData = await optimizeRes.json();

console.log('最適化されたルート:', optimizeData.optimizedRoute);
```

---

### 例2: AI にルートを生成してもらう（パイプライン使用）

```typescript
// 一発でルート生成から最適化まで完了
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

if (data.success) {
  console.log('生成されたルート名:', data.routeGeneration.routeName);
  console.log('訪問スポット:', data.routeGeneration.spots);
  console.log('最適化された順序:', data.routeOptimization.orderedWaypoints);
  console.log('総距離:', data.routeOptimization.totalDistanceMeters, 'm');
  console.log('総時間:', data.routeOptimization.totalDurationSeconds / 60, '分');
}
```

---

### 例3: タクシーシナリオを生成

```typescript
// Step 1: ルート生成
const routeRes = await fetch('/api/route/generate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    input: {
      startPoint: '東京駅',
      purpose: '皇居周辺を観光したい',
      spotCount: 5,
      model: 'gemini'
    }
  })
});
const routeData = await routeRes.json();

// Step 2: シナリオ生成
const scenarioRes = await fetch('/api/scenario', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    route: {
      routeName: routeData.data.routeName,
      spots: routeData.data.spots
    },
    models: 'both'
  })
});
const scenarioData = await scenarioRes.json();

// Step 3: シナリオ統合
const integrationRes = await fetch('/api/scenario/integrate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    integration: {
      routeName: scenarioData.data.routeName,
      spots: scenarioData.data.spots,
      sourceModel: 'gemini',
      integrationLLM: 'qwen'
    }
  })
});
const integrationData = await integrationRes.json();

console.log('統合されたシナリオ:');
console.log(integrationData.data.integratedScript);
```

---

## OpenAPI 仕様書

完全な OpenAPI 3.0 仕様書は `openapi.yaml` を参照してください。

Swagger UI などのツールで `openapi.yaml` を読み込むことで、インタラクティブなAPIドキュメントを表示できます。

---

## サポート

問題が発生した場合は、GitHub Issues でお知らせください。
