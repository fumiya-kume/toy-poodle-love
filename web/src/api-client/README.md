# Taxi Scenario Writer API Client

TypeScript SDK for Taxi Scenario Writer API

## インストール

このSDKはプロジェクトに含まれているため、特別なインストールは不要です。

## 使い方

### 基本的な使い方

```typescript
import { TaxiScenarioApiClient } from '@/api-client';

// クライアントを初期化
const client = new TaxiScenarioApiClient();

// または、カスタム設定で初期化
const client = new TaxiScenarioApiClient({
  baseUrl: 'https://api.example.com',  // 別のサーバーを使用する場合
  timeout: 60000,  // タイムアウト時間を60秒に設定
});
```

### デフォルトクライアントを使用

```typescript
import { apiClient } from '@/api-client';

// デフォルトインスタンスを直接使用
const response = await apiClient.qwenChat('こんにちは');
```

---

## API メソッド一覧

### 1. AI テキスト生成

#### Qwen AI でテキスト生成

```typescript
const response = await apiClient.qwenChat('東京の観光スポットを3つ教えてください');
console.log(response); // "東京の人気観光スポット3つをご紹介します..."
```

#### Gemini AI でテキスト生成

```typescript
const response = await apiClient.geminiChat('東京の観光スポットを3つ教えてください');
console.log(response); // "東京には多くの魅力的な観光スポットがあります..."
```

---

### 2. Places & Routes

#### 住所をジオコーディング

```typescript
const response = await apiClient.geocode({
  addresses: ['東京駅', '浅草寺', '東京スカイツリー']
});

if (response.success && response.places) {
  response.places.forEach(place => {
    console.log(`${place.inputAddress}: (${place.location.latitude}, ${place.location.longitude})`);
  });
}
```

#### ルート最適化

```typescript
const response = await apiClient.optimizeRoute({
  origin: {
    placeId: 'ChIJC3Cf2PuLGGARZ7KXBYZWe5k',
    name: '東京駅'
  },
  destination: {
    placeId: 'ChIJ5SZMmrWLGGAR205kNjohnZU',
    name: '上野公園'
  },
  intermediates: [
    { placeId: 'ChIJ8T1GpMGOGGARDYGSgpooDWw', name: '浅草寺' },
    { placeId: 'ChIJN33aMnCNGGARID5p4Dl3_4I', name: '東京スカイツリー' }
  ],
  travelMode: 'DRIVE',
  optimizeWaypointOrder: true
});

if (response.success && response.optimizedRoute) {
  const route = response.optimizedRoute;
  console.log(`総距離: ${apiClient.formatDistance(route.totalDistanceMeters)}`);
  console.log(`総時間: ${apiClient.formatDuration(route.totalDurationSeconds)}`);

  route.orderedWaypoints.forEach((wp, i) => {
    console.log(`${i + 1}. ${wp.waypoint.name}`);
  });
}
```

#### 住所リストから直接ルート最適化（ヘルパーメソッド）

```typescript
// ジオコーディングとルート最適化を一度に実行
const response = await apiClient.optimizeRouteFromAddresses(
  ['東京駅', '浅草寺', '東京スカイツリー', '上野公園'],
  'DRIVE'
);

if (response.success && response.optimizedRoute) {
  const route = response.optimizedRoute;
  console.log(`最適ルート: 総距離 ${apiClient.formatDistance(route.totalDistanceMeters)}`);
}
```

---

### 3. パイプライン（E2E）

#### AI ルート最適化パイプライン

```typescript
const response = await apiClient.pipelineRouteOptimize({
  startPoint: '東京駅',
  purpose: '皇居周辺の観光スポットを巡りたい',
  spotCount: 5,
  model: 'gemini'
});

if (response.success) {
  // AI が生成したルート名
  console.log('ルート名:', response.routeGeneration.routeName);

  // 生成されたスポット
  console.log('スポット:', response.routeGeneration.spots);

  // 最適化されたルート
  console.log('総距離:', apiClient.formatDistance(
    response.routeOptimization.totalDistanceMeters!
  ));
  console.log('総時間:', apiClient.formatDuration(
    response.routeOptimization.totalDurationSeconds!
  ));

  // 処理時間
  console.log('合計処理時間:', response.totalProcessingTimeMs, 'ms');
}
```

---

### 4. シナリオ生成

#### AI によるルート自動生成

```typescript
const response = await apiClient.generateRoute({
  input: {
    startPoint: '東京駅',
    purpose: '皇居周辺を観光したい',
    spotCount: 5,
    model: 'gemini',
    language: 'ja'
  }
});

if (response.success && response.data) {
  console.log('ルート名:', response.data.routeName);
  console.log('スポット:', response.data.spots);
  console.log('処理時間:', response.data.processingTimeMs, 'ms');
}
```

#### タクシーシナリオ生成

```typescript
const response = await apiClient.generateScenario({
  route: {
    routeName: '皇居周辺観光ツアー',
    spots: [
      {
        name: '東京駅',
        type: 'start',
        description: '赤レンガ駅舎',
        point: '歴史的建築'
      },
      {
        name: '皇居東御苑',
        type: 'waypoint',
        description: '旧江戸城本丸',
        point: '日本庭園'
      }
    ],
    language: 'ja'
  },
  models: 'both'
});

if (response.success && response.data) {
  response.data.spots.forEach(spot => {
    console.log(`\n=== ${spot.name} ===`);
    if (spot.qwen) console.log('Qwen:', spot.qwen);
    if (spot.gemini) console.log('Gemini:', spot.gemini);
  });
}
```

#### 単一地点のシナリオ生成

```typescript
const response = await apiClient.generateSpotScenario({
  routeName: '皇居周辺観光ツアー',
  spotName: '皇居東御苑',
  description: '旧江戸城の本丸跡地',
  point: '四季折々の花が楽しめる日本庭園',
  models: 'both'
});

if (response.success && response.scenario) {
  console.log('Qwen:', response.scenario.qwen);
  console.log('Gemini:', response.scenario.gemini);
}
```

#### シナリオ統合

```typescript
// まず各地点のシナリオを生成
const scenarioRes = await apiClient.generateScenario({
  route: {
    routeName: '皇居周辺観光ツアー',
    spots: [/* ... */]
  },
  models: 'both'
});

// 生成されたシナリオを統合
const integrationRes = await apiClient.integrateScenario({
  integration: {
    routeName: scenarioRes.data!.routeName,
    spots: scenarioRes.data!.spots,
    sourceModel: 'gemini',
    integrationLLM: 'qwen'  // 省略可能。省略時はsourceModelと異なる方を使用
  }
});

if (integrationRes.success && integrationRes.data) {
  console.log('統合されたシナリオ:');
  console.log(integrationRes.data.integratedScript);
  console.log('\n処理時間:', integrationRes.data.processingTimeMs, 'ms');
}
```

---

## ユーティリティメソッド

### 距離フォーマット

```typescript
console.log(apiClient.formatDistance(1500));   // "1500 m"
console.log(apiClient.formatDistance(8500));   // "8.5 km"
```

### 時間フォーマット

```typescript
console.log(apiClient.formatDuration(300));    // "5分"
console.log(apiClient.formatDuration(3900));   // "1時間5分"
```

---

## エラーハンドリング

```typescript
try {
  const response = await apiClient.qwenChat('こんにちは');
  console.log(response);
} catch (error) {
  if (error instanceof Error) {
    console.error('エラー:', error.message);
  }
}
```

---

## 完全な使用例

### 例1: 手動でルートを作成

```typescript
import { apiClient } from '@/api-client';

async function createManualRoute() {
  try {
    // 住所リストから直接最適化
    const response = await apiClient.optimizeRouteFromAddresses(
      ['東京駅', '浅草寺', '東京スカイツリー', '上野公園'],
      'DRIVE'
    );

    if (response.success && response.optimizedRoute) {
      const route = response.optimizedRoute;

      console.log('=== 最適化されたルート ===');
      console.log(`総距離: ${apiClient.formatDistance(route.totalDistanceMeters)}`);
      console.log(`総時間: ${apiClient.formatDuration(route.totalDurationSeconds)}`);

      console.log('\n順序:');
      route.orderedWaypoints.forEach((wp, i) => {
        console.log(`  ${i + 1}. ${wp.waypoint.name}`);

        if (route.legs[i]) {
          const leg = route.legs[i];
          console.log(`     → ${apiClient.formatDistance(leg.distanceMeters)} (${apiClient.formatDuration(leg.durationSeconds)})`);
        }
      });
    }
  } catch (error) {
    console.error('エラー:', error);
  }
}

createManualRoute();
```

### 例2: AI にお任せ（パイプライン使用）

```typescript
import { apiClient } from '@/api-client';

async function createAiRoute() {
  try {
    const response = await apiClient.pipelineRouteOptimize({
      startPoint: '東京駅',
      purpose: '皇居周辺の観光スポットを巡りたい',
      spotCount: 5,
      model: 'gemini'
    });

    if (response.success) {
      console.log('=== AI が生成したルート ===');
      console.log(`ルート名: ${response.routeGeneration.routeName}`);

      console.log('\nスポット:');
      response.routeGeneration.spots?.forEach((spot, i) => {
        console.log(`  ${i + 1}. ${spot.name}`);
        if (spot.description) {
          console.log(`     ${spot.description}`);
        }
      });

      console.log('\n最適化結果:');
      console.log(`総距離: ${apiClient.formatDistance(
        response.routeOptimization.totalDistanceMeters!
      )}`);
      console.log(`総時間: ${apiClient.formatDuration(
        response.routeOptimization.totalDurationSeconds!
      )}`);

      console.log('\n処理時間:');
      console.log(`  ルート生成: ${response.routeGeneration.processingTimeMs}ms`);
      console.log(`  ジオコーディング: ${response.geocoding.processingTimeMs}ms`);
      console.log(`  ルート最適化: ${response.routeOptimization.processingTimeMs}ms`);
      console.log(`  合計: ${response.totalProcessingTimeMs}ms`);
    }
  } catch (error) {
    console.error('エラー:', error);
  }
}

createAiRoute();
```

### 例3: フルフロー（ルート生成 → シナリオ生成 → 統合）

```typescript
import { apiClient } from '@/api-client';

async function generateFullScenario() {
  try {
    // Step 1: AI がルートを生成
    console.log('Step 1: ルート生成中...');
    const routeRes = await apiClient.generateRoute({
      input: {
        startPoint: '東京駅',
        purpose: '皇居周辺を観光したい',
        spotCount: 5,
        model: 'gemini'
      }
    });

    if (!routeRes.success || !routeRes.data) {
      throw new Error('ルート生成に失敗しました');
    }

    console.log(`✓ ルート生成完了: ${routeRes.data.routeName}`);

    // Step 2: 各地点のシナリオを生成
    console.log('\nStep 2: シナリオ生成中...');
    const scenarioRes = await apiClient.generateScenario({
      route: {
        routeName: routeRes.data.routeName,
        spots: routeRes.data.spots
      },
      models: 'both'
    });

    if (!scenarioRes.success || !scenarioRes.data) {
      throw new Error('シナリオ生成に失敗しました');
    }

    console.log(`✓ シナリオ生成完了 (${scenarioRes.data.stats.totalSpots}地点)`);

    // Step 3: シナリオを統合
    console.log('\nStep 3: シナリオ統合中...');
    const integrationRes = await apiClient.integrateScenario({
      integration: {
        routeName: scenarioRes.data.routeName,
        spots: scenarioRes.data.spots,
        sourceModel: 'gemini',
        integrationLLM: 'qwen'
      }
    });

    if (!integrationRes.success || !integrationRes.data) {
      throw new Error('シナリオ統合に失敗しました');
    }

    console.log('✓ シナリオ統合完了');

    // 最終結果を表示
    console.log('\n' + '='.repeat(50));
    console.log(`【${integrationRes.data.routeName}】`);
    console.log('='.repeat(50));
    console.log(integrationRes.data.integratedScript);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('エラー:', error);
  }
}

generateFullScenario();
```

---

## React コンポーネントでの使用例

```typescript
import { useState } from 'react';
import { apiClient } from '@/api-client';
import type { PipelineResponse } from '@/types/pipeline';

export function RouteGenerator() {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<PipelineResponse | null>(null);

  const handleGenerate = async () => {
    setLoading(true);
    try {
      const response = await apiClient.pipelineRouteOptimize({
        startPoint: '東京駅',
        purpose: '皇居周辺の観光スポットを巡りたい',
        spotCount: 5,
        model: 'gemini'
      });

      if (response.success) {
        setResult(response);
      }
    } catch (error) {
      console.error('エラー:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <button onClick={handleGenerate} disabled={loading}>
        {loading ? '生成中...' : 'ルートを生成'}
      </button>

      {result && (
        <div>
          <h2>{result.routeGeneration.routeName}</h2>
          <p>総距離: {apiClient.formatDistance(result.routeOptimization.totalDistanceMeters!)}</p>
          <p>総時間: {apiClient.formatDuration(result.routeOptimization.totalDurationSeconds!)}</p>
        </div>
      )}
    </div>
  );
}
```

---

## TypeScript 型定義

すべての型定義は以下のファイルで確認できます:
- `src/types/place-route.ts`
- `src/types/pipeline.ts`
- `src/types/api.ts`
- `src/types/scenario.ts`
- `src/types/route.ts`
