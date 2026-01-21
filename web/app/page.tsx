'use client';

import { useState } from 'react';
import {
  GeocodedPlace,
  RouteOptimizationResponse,
  OptimizedWaypoint,
  RouteLeg,
} from '../src/types/place-route';
import { PipelineResponse } from '../src/types/pipeline';
import { ScenarioOutput, SpotScenario, RouteSpot } from '../src/types/scenario';
import { ScenarioResponse } from '../src/types/api';

type TabType = 'ai' | 'route' | 'ai-route';

interface ModelResponse {
  qwen?: string;
  gemini?: string;
}

interface OptimizedRouteResult {
  orderedWaypoints: OptimizedWaypoint[];
  legs: RouteLeg[];
  totalDistanceMeters: number;
  totalDurationSeconds: number;
}

export default function Home() {
  const [activeTab, setActiveTab] = useState<TabType>('ai-route');

  // AI テキスト生成用のstate
  const [message, setMessage] = useState('');
  const [enabledModels, setEnabledModels] = useState({
    qwen: true,
    gemini: true,
  });
  const [responses, setResponses] = useState<ModelResponse>({});
  const [aiLoading, setAiLoading] = useState(false);

  // ルート最適化用のstate
  const [placesInput, setPlacesInput] = useState('');
  const [routeLoading, setRouteLoading] = useState(false);
  const [geocodedPlaces, setGeocodedPlaces] = useState<GeocodedPlace[]>([]);
  const [optimizedRoute, setOptimizedRoute] = useState<OptimizedRouteResult | null>(null);
  const [routeError, setRouteError] = useState<string | null>(null);

  // AI ルート最適化用のstate
  const [aiRouteStartPoint, setAiRouteStartPoint] = useState('');
  const [aiRoutePurpose, setAiRoutePurpose] = useState('');
  const [aiRouteSpotCount, setAiRouteSpotCount] = useState(5);
  const [aiRouteModel, setAiRouteModel] = useState<'qwen' | 'gemini'>('gemini');
  const [aiRouteLoading, setAiRouteLoading] = useState(false);
  const [aiRouteResult, setAiRouteResult] = useState<PipelineResponse | null>(null);
  const [aiRouteError, setAiRouteError] = useState<string | null>(null);

  // シナリオガイド用のstate
  const [scenarioData, setScenarioData] = useState<ScenarioOutput | null>(null);
  const [scenarioLoading, setScenarioLoading] = useState(false);
  const [selectedSpotIndex, setSelectedSpotIndex] = useState<number | null>(null);
  const [spotModalOpen, setSpotModalOpen] = useState(false);

  const handleModelToggle = (model: 'qwen' | 'gemini') => {
    setEnabledModels(prev => ({
      ...prev,
      [model]: !prev[model],
    }));
  };

  const handleAiSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!message.trim()) {
      alert('メッセージを入力してください');
      return;
    }

    if (!enabledModels.qwen && !enabledModels.gemini) {
      alert('少なくとも1つのモデルを選択してください');
      return;
    }

    setAiLoading(true);
    setResponses({});

    const apiCalls = [];

    if (enabledModels.qwen) {
      apiCalls.push(
        fetch('/api/qwen', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message }),
        })
          .then(res => res.json())
          .then(data => ({ model: 'qwen' as const, data }))
          .catch(error => ({ model: 'qwen' as const, error: String(error) }))
      );
    }

    if (enabledModels.gemini) {
      apiCalls.push(
        fetch('/api/gemini', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message }),
        })
          .then(res => res.json())
          .then(data => ({ model: 'gemini' as const, data }))
          .catch(error => ({ model: 'gemini' as const, error: String(error) }))
      );
    }

    try {
      const results = await Promise.all(apiCalls);
      const newResponses: ModelResponse = {};

      results.forEach(result => {
        if ('error' in result) {
          newResponses[result.model] = `エラー: ${result.error}`;
        } else if (result.data.error) {
          newResponses[result.model] = `エラー: ${result.data.error}`;
        } else {
          newResponses[result.model] = result.data.response;
        }
      });

      setResponses(newResponses);
    } catch (error) {
      console.error('API呼び出しエラー:', error);
    } finally {
      setAiLoading(false);
    }
  };

  const handleRouteOptimize = async (e: React.FormEvent) => {
    e.preventDefault();

    const lines = placesInput.trim().split('\n').filter(line => line.trim());
    if (lines.length < 2) {
      alert('2つ以上の地点を入力してください（1行に1地点）');
      return;
    }

    setRouteLoading(true);
    setRouteError(null);
    setGeocodedPlaces([]);
    setOptimizedRoute(null);

    try {
      // Step 1: ジオコーディング
      const geocodeRes = await fetch('/api/places/geocode', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ addresses: lines }),
      });
      const geocodeData = await geocodeRes.json();

      if (!geocodeData.success) {
        throw new Error(geocodeData.error || 'ジオコーディングに失敗しました');
      }

      const places: GeocodedPlace[] = geocodeData.places;
      setGeocodedPlaces(places);

      if (places.length < 2) {
        throw new Error('有効な地点が2つ以上見つかりませんでした');
      }

      // Step 2: ルート最適化
      // 最初の地点を出発地、最後の地点を目的地、中間を経由地点とする
      const origin = { placeId: places[0].placeId, name: places[0].inputAddress };
      const destination = { placeId: places[places.length - 1].placeId, name: places[places.length - 1].inputAddress };
      const intermediates = places.slice(1, -1).map(p => ({
        placeId: p.placeId,
        name: p.inputAddress,
      }));

      const optimizeRes = await fetch('/api/routes/optimize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          origin,
          destination,
          intermediates,
          travelMode: 'DRIVE',
          optimizeWaypointOrder: true,
        }),
      });
      const optimizeData: RouteOptimizationResponse = await optimizeRes.json();

      if (!optimizeData.success || !optimizeData.optimizedRoute) {
        throw new Error(optimizeData.error || 'ルート最適化に失敗しました');
      }

      setOptimizedRoute(optimizeData.optimizedRoute);
    } catch (error) {
      console.error('ルート最適化エラー:', error);
      setRouteError(error instanceof Error ? error.message : 'エラーが発生しました');
    } finally {
      setRouteLoading(false);
    }
  };

  const handleAiRouteOptimize = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!aiRouteStartPoint.trim()) {
      alert('出発地点を入力してください');
      return;
    }

    if (!aiRoutePurpose.trim()) {
      alert('目的・テーマを入力してください');
      return;
    }

    setAiRouteLoading(true);
    setAiRouteError(null);
    setAiRouteResult(null);
    setScenarioData(null);

    try {
      const res = await fetch('/api/pipeline/route-optimize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          startPoint: aiRouteStartPoint,
          purpose: aiRoutePurpose,
          spotCount: aiRouteSpotCount,
          model: aiRouteModel,
        }),
      });

      const data: PipelineResponse = await res.json();

      if (!data.success) {
        throw new Error(data.error || 'パイプライン処理に失敗しました');
      }

      setAiRouteResult(data);

      // ルート最適化成功後、自動的にシナリオガイドを生成
      if (data.routeGeneration.spots && data.routeGeneration.routeName) {
        setScenarioLoading(true);
        try {
          const spots: RouteSpot[] = data.routeGeneration.spots.map((spot) => ({
            name: spot.name,
            type: spot.type,
            description: spot.description,
            point: spot.point,
          }));

          const scenarioRes = await fetch('/api/scenario', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              route: {
                routeName: data.routeGeneration.routeName,
                spots,
              },
              models: 'both',
              includeImagePrompt: false,
            }),
          });

          const scenarioResult: ScenarioResponse = await scenarioRes.json();

          if (scenarioResult.success && scenarioResult.data) {
            setScenarioData(scenarioResult.data);
          }
        } catch (scenarioError) {
          console.error('シナリオ自動生成エラー:', scenarioError);
          // シナリオ生成失敗はアラートを出さず、手動生成ボタンで再試行可能にする
        } finally {
          setScenarioLoading(false);
        }
      }
    } catch (error) {
      console.error('AI ルート最適化エラー:', error);
      setAiRouteError(error instanceof Error ? error.message : 'エラーが発生しました');
    } finally {
      setAiRouteLoading(false);
    }
  };

  const formatDistance = (meters: number) => {
    if (meters >= 1000) {
      return `${(meters / 1000).toFixed(1)} km`;
    }
    return `${meters} m`;
  };

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) {
      return `${hours}時間${minutes}分`;
    }
    return `${minutes}分`;
  };

  const getStepStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return '#22c55e';
      case 'in_progress': return '#f59e0b';
      case 'failed': return '#ef4444';
      default: return '#9ca3af';
    }
  };

  const getStepStatusText = (status: string) => {
    switch (status) {
      case 'completed': return '完了';
      case 'in_progress': return '処理中';
      case 'failed': return '失敗';
      default: return '待機中';
    }
  };

  // シナリオガイドを生成する関数
  const handleGenerateScenario = async () => {
    if (!aiRouteResult?.routeGeneration.spots || !aiRouteResult?.routeGeneration.routeName) {
      alert('ルートデータがありません');
      return;
    }

    setScenarioLoading(true);

    try {
      // パイプライン結果からRouteSpot配列を作成
      const spots: RouteSpot[] = aiRouteResult.routeGeneration.spots.map((spot) => ({
        name: spot.name,
        type: spot.type,
        description: spot.description,
        point: spot.point,
      }));

      const response = await fetch('/api/scenario', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          route: {
            routeName: aiRouteResult.routeGeneration.routeName,
            spots,
          },
          models: 'both',
          includeImagePrompt: false,
        }),
      });

      const data: ScenarioResponse = await response.json();

      if (!data.success || !data.data) {
        throw new Error(data.error || 'シナリオ生成に失敗しました');
      }

      setScenarioData(data.data);
    } catch (error) {
      console.error('シナリオ生成エラー:', error);
      alert(error instanceof Error ? error.message : 'シナリオ生成に失敗しました');
    } finally {
      setScenarioLoading(false);
    }
  };

  // 地点クリック時にモーダルを開く
  const handleSpotClick = (index: number) => {
    setSelectedSpotIndex(index);
    setSpotModalOpen(true);
  };

  // モーダルを閉じる
  const closeSpotModal = () => {
    setSpotModalOpen(false);
    setSelectedSpotIndex(null);
  };

  // 選択した地点のシナリオを取得
  const getSelectedSpotScenario = (): SpotScenario | null => {
    if (selectedSpotIndex === null || !scenarioData) return null;

    // 最適化後の順序に基づいてシナリオを検索
    const orderedWaypoints = aiRouteResult?.routeOptimization.orderedWaypoints;
    if (!orderedWaypoints || selectedSpotIndex >= orderedWaypoints.length) return null;

    const waypointName = orderedWaypoints[selectedSpotIndex].waypoint.name;
    return scenarioData.spots.find(s => s.name === waypointName) || null;
  };

  return (
    <div style={{
      maxWidth: '800px',
      margin: '0 auto',
      padding: '40px 20px',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    }}>
      <h1 style={{ fontSize: '32px', marginBottom: '32px', textAlign: 'center' }}>
        Taxi Scenario Writer
      </h1>

      {/* タブ切り替え */}
      <div style={{
        display: 'flex',
        gap: '8px',
        marginBottom: '24px',
        borderBottom: '2px solid #e5e7eb'
      }}>
        <button
          onClick={() => setActiveTab('ai-route')}
          style={{
            padding: '12px 24px',
            fontSize: '16px',
            fontWeight: activeTab === 'ai-route' ? '600' : '400',
            backgroundColor: 'transparent',
            color: activeTab === 'ai-route' ? '#8b5cf6' : '#6b7280',
            border: 'none',
            borderBottom: activeTab === 'ai-route' ? '2px solid #8b5cf6' : '2px solid transparent',
            marginBottom: '-2px',
            cursor: 'pointer',
          }}
        >
          AI ルート最適化
        </button>
        <button
          onClick={() => setActiveTab('route')}
          style={{
            padding: '12px 24px',
            fontSize: '16px',
            fontWeight: activeTab === 'route' ? '600' : '400',
            backgroundColor: 'transparent',
            color: activeTab === 'route' ? '#0070f3' : '#6b7280',
            border: 'none',
            borderBottom: activeTab === 'route' ? '2px solid #0070f3' : '2px solid transparent',
            marginBottom: '-2px',
            cursor: 'pointer',
          }}
        >
          ルート最適化
        </button>
        <button
          onClick={() => setActiveTab('ai')}
          style={{
            padding: '12px 24px',
            fontSize: '16px',
            fontWeight: activeTab === 'ai' ? '600' : '400',
            backgroundColor: 'transparent',
            color: activeTab === 'ai' ? '#0070f3' : '#6b7280',
            border: 'none',
            borderBottom: activeTab === 'ai' ? '2px solid #0070f3' : '2px solid transparent',
            marginBottom: '-2px',
            cursor: 'pointer',
          }}
        >
          AI テキスト生成
        </button>
      </div>

      {/* AI ルート最適化タブ */}
      {activeTab === 'ai-route' && (
        <div>
          <form onSubmit={handleAiRouteOptimize}>
            <div style={{ marginBottom: '24px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600'
              }}>
                出発地点:
              </label>
              <input
                type="text"
                value={aiRouteStartPoint}
                onChange={(e) => setAiRouteStartPoint(e.target.value)}
                placeholder="例: 東京駅"
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '16px',
                  border: '1px solid #ccc',
                  borderRadius: '8px',
                  fontFamily: 'inherit'
                }}
              />
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600'
              }}>
                目的・テーマ:
              </label>
              <input
                type="text"
                value={aiRoutePurpose}
                onChange={(e) => setAiRoutePurpose(e.target.value)}
                placeholder="例: 皇居周辺の観光スポットを巡りたい"
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '16px',
                  border: '1px solid #ccc',
                  borderRadius: '8px',
                  fontFamily: 'inherit'
                }}
              />
            </div>

            <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
              <div style={{ flex: 1 }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600'
                }}>
                  地点数:
                </label>
                <select
                  value={aiRouteSpotCount}
                  onChange={(e) => setAiRouteSpotCount(Number(e.target.value))}
                  style={{
                    width: '100%',
                    padding: '12px',
                    fontSize: '16px',
                    border: '1px solid #ccc',
                    borderRadius: '8px',
                    fontFamily: 'inherit',
                    backgroundColor: 'white'
                  }}
                >
                  {[3, 4, 5, 6, 7, 8].map(n => (
                    <option key={n} value={n}>{n}地点</option>
                  ))}
                </select>
              </div>

              <div style={{ flex: 1 }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600'
                }}>
                  AIモデル:
                </label>
                <select
                  value={aiRouteModel}
                  onChange={(e) => setAiRouteModel(e.target.value as 'qwen' | 'gemini')}
                  style={{
                    width: '100%',
                    padding: '12px',
                    fontSize: '16px',
                    border: '1px solid #ccc',
                    borderRadius: '8px',
                    fontFamily: 'inherit',
                    backgroundColor: 'white'
                  }}
                >
                  <option value="gemini">Gemini</option>
                  <option value="qwen">Qwen</option>
                </select>
              </div>
            </div>

            <button
              type="submit"
              disabled={aiRouteLoading || scenarioLoading}
              style={{
                width: '100%',
                padding: '12px 24px',
                fontSize: '16px',
                fontWeight: '600',
                backgroundColor: (aiRouteLoading || scenarioLoading) ? '#ccc' : '#8b5cf6',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: (aiRouteLoading || scenarioLoading) ? 'not-allowed' : 'pointer',
                transition: 'background-color 0.2s'
              }}
            >
              {aiRouteLoading ? '処理中...' : scenarioLoading ? 'ガイド生成中...' : '🎤 AI でルート＆ガイドを生成'}
            </button>
          </form>

          {/* エラー表示 */}
          {aiRouteError && (
            <div style={{
              marginTop: '24px',
              padding: '16px',
              backgroundColor: '#fef2f2',
              border: '1px solid #fecaca',
              borderRadius: '8px',
              color: '#dc2626'
            }}>
              {aiRouteError}
            </div>
          )}

          {/* ステップ進捗表示 */}
          {(aiRouteLoading || scenarioLoading) && (
            <div style={{ marginTop: '24px' }}>
              <h3 style={{ fontSize: '18px', marginBottom: '12px', fontWeight: '600' }}>
                処理中...
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: aiRouteResult ? '#22c55e' : '#f59e0b',
                    animation: aiRouteResult ? 'none' : 'pulse 1s infinite'
                  }} />
                  <span style={{ color: aiRouteResult ? '#22c55e' : undefined }}>
                    1. AIがルートを生成{aiRouteResult ? ' ✓' : '中...'}
                  </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: aiRouteResult ? '#22c55e' : '#9ca3af'
                  }} />
                  <span style={{ color: aiRouteResult ? '#22c55e' : '#9ca3af' }}>
                    2. 座標を取得{aiRouteResult ? ' ✓' : ''}
                  </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: aiRouteResult ? '#22c55e' : '#9ca3af'
                  }} />
                  <span style={{ color: aiRouteResult ? '#22c55e' : '#9ca3af' }}>
                    3. ルートを最適化{aiRouteResult ? ' ✓' : ''}
                  </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: scenarioData ? '#22c55e' : scenarioLoading ? '#f59e0b' : '#9ca3af',
                    animation: scenarioLoading && !scenarioData ? 'pulse 1s infinite' : 'none'
                  }} />
                  <span style={{ color: scenarioData ? '#22c55e' : scenarioLoading ? undefined : '#9ca3af' }}>
                    4. 観光ガイドを生成{scenarioData ? ' ✓' : scenarioLoading ? '中...' : ''}
                  </span>
                </div>
              </div>
            </div>
          )}

          {/* 結果表示 */}
          {aiRouteResult && (
            <div style={{ marginTop: '24px' }}>
              {/* ステップ完了状況 */}
              <div style={{
                padding: '16px',
                backgroundColor: '#f9fafb',
                borderRadius: '8px',
                marginBottom: '16px'
              }}>
                <h3 style={{ fontSize: '16px', marginBottom: '12px', fontWeight: '600' }}>
                  処理ステップ
                </h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{
                      width: '12px',
                      height: '12px',
                      borderRadius: '50%',
                      backgroundColor: getStepStatusColor(aiRouteResult.routeGeneration.status)
                    }} />
                    <span>1. AI ルート生成: {getStepStatusText(aiRouteResult.routeGeneration.status)}</span>
                    {aiRouteResult.routeGeneration.processingTimeMs && (
                      <span style={{ fontSize: '12px', color: '#6b7280' }}>
                        ({aiRouteResult.routeGeneration.processingTimeMs}ms)
                      </span>
                    )}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{
                      width: '12px',
                      height: '12px',
                      borderRadius: '50%',
                      backgroundColor: getStepStatusColor(aiRouteResult.geocoding.status)
                    }} />
                    <span>2. ジオコーディング: {getStepStatusText(aiRouteResult.geocoding.status)}</span>
                    {aiRouteResult.geocoding.processingTimeMs && (
                      <span style={{ fontSize: '12px', color: '#6b7280' }}>
                        ({aiRouteResult.geocoding.processingTimeMs}ms)
                      </span>
                    )}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{
                      width: '12px',
                      height: '12px',
                      borderRadius: '50%',
                      backgroundColor: getStepStatusColor(aiRouteResult.routeOptimization.status)
                    }} />
                    <span>3. ルート最適化: {getStepStatusText(aiRouteResult.routeOptimization.status)}</span>
                    {aiRouteResult.routeOptimization.processingTimeMs && (
                      <span style={{ fontSize: '12px', color: '#6b7280' }}>
                        ({aiRouteResult.routeOptimization.processingTimeMs}ms)
                      </span>
                    )}
                  </div>
                </div>
                <p style={{ marginTop: '12px', fontSize: '14px', color: '#6b7280' }}>
                  総処理時間: {aiRouteResult.totalProcessingTimeMs}ms
                </p>
              </div>

              {/* 生成されたルート名 */}
              {aiRouteResult.routeGeneration.routeName && (
                <div style={{
                  padding: '16px',
                  backgroundColor: '#ede9fe',
                  border: '2px solid #8b5cf6',
                  borderRadius: '8px',
                  marginBottom: '16px'
                }}>
                  <h3 style={{ fontSize: '20px', fontWeight: '700', color: '#5b21b6', margin: 0 }}>
                    {aiRouteResult.routeGeneration.routeName}
                  </h3>
                </div>
              )}

              {/* 生成されたスポット一覧 */}
              {aiRouteResult.routeGeneration.spots && (
                <div style={{ marginBottom: '24px' }}>
                  <h3 style={{ fontSize: '18px', marginBottom: '12px', fontWeight: '600' }}>
                    AI が生成したスポット
                  </h3>
                  <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                    {aiRouteResult.routeGeneration.spots.map((spot, i) => (
                      <li key={i} style={{
                        padding: '12px',
                        backgroundColor: '#f9fafb',
                        borderRadius: '8px',
                        marginBottom: '8px'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <span style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            width: '24px',
                            height: '24px',
                            borderRadius: '50%',
                            backgroundColor: spot.type === 'start' ? '#22c55e' : spot.type === 'destination' ? '#ef4444' : '#3b82f6',
                            color: 'white',
                            fontSize: '12px',
                            fontWeight: '600'
                          }}>
                            {i + 1}
                          </span>
                          <strong>{spot.name}</strong>
                          <span style={{
                            fontSize: '12px',
                            padding: '2px 8px',
                            backgroundColor: spot.type === 'start' ? '#dcfce7' : spot.type === 'destination' ? '#fee2e2' : '#dbeafe',
                            color: spot.type === 'start' ? '#166534' : spot.type === 'destination' ? '#991b1b' : '#1e40af',
                            borderRadius: '12px'
                          }}>
                            {spot.type === 'start' ? '出発' : spot.type === 'destination' ? '到着' : '経由'}
                          </span>
                        </div>
                        {spot.description && (
                          <p style={{ margin: '8px 0 0 32px', fontSize: '14px', color: '#6b7280' }}>
                            {spot.description}
                          </p>
                        )}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* 最適化されたルート */}
              {aiRouteResult.routeOptimization.orderedWaypoints && (
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
                    <h3 style={{ fontSize: '20px', fontWeight: '600', margin: 0 }}>
                      最適化されたルート
                    </h3>
                    <button
                      onClick={handleGenerateScenario}
                      disabled={scenarioLoading}
                      style={{
                        padding: '8px 16px',
                        fontSize: '14px',
                        fontWeight: '600',
                        backgroundColor: scenarioLoading ? '#ccc' : scenarioData ? '#22c55e' : '#8b5cf6',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: scenarioLoading ? 'not-allowed' : 'pointer',
                      }}
                    >
                      {scenarioLoading ? '生成中...' : scenarioData ? '✓ ガイド生成済み' : '🎤 ガイドを一括生成'}
                    </button>
                  </div>

                  <div style={{
                    padding: '16px',
                    backgroundColor: '#f0fdf4',
                    border: '2px solid #22c55e',
                    borderRadius: '8px',
                    marginBottom: '16px'
                  }}>
                    <div style={{ display: 'flex', gap: '24px', justifyContent: 'center' }}>
                      <div>
                        <span style={{ fontSize: '14px', color: '#6b7280' }}>総距離</span>
                        <p style={{ fontSize: '24px', fontWeight: '700', margin: '4px 0 0', color: '#166534' }}>
                          {formatDistance(aiRouteResult.routeOptimization.totalDistanceMeters!)}
                        </p>
                      </div>
                      <div>
                        <span style={{ fontSize: '14px', color: '#6b7280' }}>総所要時間</span>
                        <p style={{ fontSize: '24px', fontWeight: '700', margin: '4px 0 0', color: '#166534' }}>
                          {formatDuration(aiRouteResult.routeOptimization.totalDurationSeconds!)}
                        </p>
                      </div>
                    </div>
                  </div>

                  {scenarioData && (
                    <p style={{ marginBottom: '12px', fontSize: '14px', color: '#6b7280' }}>
                      💡 地点をクリックすると観光ガイドを確認できます
                    </p>
                  )}

                  <ol style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                    {aiRouteResult.routeOptimization.orderedWaypoints.map((wp, i) => {
                      const hasScenario = scenarioData?.spots.some(s => s.name === wp.waypoint.name);
                      return (
                        <li
                          key={i}
                          onClick={() => hasScenario && handleSpotClick(i)}
                          style={{
                            display: 'flex',
                            alignItems: 'flex-start',
                            gap: '12px',
                            padding: '16px',
                            marginBottom: '8px',
                            borderRadius: '8px',
                            backgroundColor: hasScenario ? '#faf5ff' : '#f9fafb',
                            border: hasScenario ? '2px solid #c4b5fd' : '1px solid #e5e7eb',
                            cursor: hasScenario ? 'pointer' : 'default',
                            transition: 'all 0.2s',
                          }}
                          onMouseEnter={(e) => {
                            if (hasScenario) {
                              e.currentTarget.style.backgroundColor = '#ede9fe';
                              e.currentTarget.style.borderColor = '#8b5cf6';
                            }
                          }}
                          onMouseLeave={(e) => {
                            if (hasScenario) {
                              e.currentTarget.style.backgroundColor = '#faf5ff';
                              e.currentTarget.style.borderColor = '#c4b5fd';
                            }
                          }}
                        >
                          <div style={{
                            width: '32px',
                            height: '32px',
                            borderRadius: '50%',
                            backgroundColor: i === 0 ? '#22c55e' : i === aiRouteResult.routeOptimization.orderedWaypoints!.length - 1 ? '#ef4444' : '#3b82f6',
                            color: 'white',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: '600',
                            flexShrink: 0
                          }}>
                            {i + 1}
                          </div>
                          <div style={{ flex: 1 }}>
                            <p style={{ margin: 0, fontWeight: '600', fontSize: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                              {wp.waypoint.name || `地点 ${i + 1}`}
                              {hasScenario && (
                                <span style={{ fontSize: '12px', color: '#8b5cf6' }}>🎤 ガイドあり</span>
                              )}
                            </p>
                            <p style={{ margin: '4px 0 0', fontSize: '14px', color: '#6b7280' }}>
                              {i === 0 ? '出発地点' : i === aiRouteResult.routeOptimization.orderedWaypoints!.length - 1 ? '到着地点' : '経由地点'}
                            </p>
                          </div>
                          {aiRouteResult.routeOptimization.legs && aiRouteResult.routeOptimization.legs[i] && (
                            <div style={{ textAlign: 'right', fontSize: '14px', color: '#6b7280' }}>
                              <p style={{ margin: 0 }}>
                                {formatDistance(aiRouteResult.routeOptimization.legs[i].distanceMeters)}
                              </p>
                              <p style={{ margin: '2px 0 0' }}>
                                {formatDuration(aiRouteResult.routeOptimization.legs[i].durationSeconds)}
                              </p>
                            </div>
                          )}
                        </li>
                      );
                    })}
                  </ol>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* ルート最適化タブ */}
      {activeTab === 'route' && (
        <div>
          <form onSubmit={handleRouteOptimize}>
            <div style={{ marginBottom: '24px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600'
              }}>
                訪問したい場所（1行に1地点）:
              </label>
              <textarea
                value={placesInput}
                onChange={(e) => setPlacesInput(e.target.value)}
                placeholder="東京駅&#10;浅草寺&#10;スカイツリー&#10;上野公園"
                rows={6}
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '16px',
                  border: '1px solid #ccc',
                  borderRadius: '8px',
                  resize: 'vertical',
                  fontFamily: 'inherit'
                }}
              />
              <p style={{ marginTop: '8px', fontSize: '14px', color: '#6b7280' }}>
                最初の地点が出発地、最後の地点が目的地になります。中間地点の順序が最適化されます。
              </p>
            </div>

            <button
              type="submit"
              disabled={routeLoading}
              style={{
                width: '100%',
                padding: '12px 24px',
                fontSize: '16px',
                fontWeight: '600',
                backgroundColor: routeLoading ? '#ccc' : '#10b981',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: routeLoading ? 'not-allowed' : 'pointer',
                transition: 'background-color 0.2s'
              }}
            >
              {routeLoading ? '計算中...' : '最適ルートを計算'}
            </button>
          </form>

          {/* エラー表示 */}
          {routeError && (
            <div style={{
              marginTop: '24px',
              padding: '16px',
              backgroundColor: '#fef2f2',
              border: '1px solid #fecaca',
              borderRadius: '8px',
              color: '#dc2626'
            }}>
              {routeError}
            </div>
          )}

          {/* ジオコーディング結果 */}
          {geocodedPlaces.length > 0 && !optimizedRoute && (
            <div style={{ marginTop: '24px' }}>
              <h3 style={{ fontSize: '18px', marginBottom: '12px', fontWeight: '600' }}>
                座標取得完了
              </h3>
              <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                {geocodedPlaces.map((place, i) => (
                  <li key={i} style={{
                    padding: '8px 0',
                    borderBottom: '1px solid #e5e7eb'
                  }}>
                    <strong>{place.inputAddress}</strong>
                    <br />
                    <span style={{ fontSize: '14px', color: '#6b7280' }}>
                      {place.formattedAddress}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* 最適化されたルート */}
          {optimizedRoute && (
            <div style={{ marginTop: '24px' }}>
              <h3 style={{ fontSize: '20px', marginBottom: '16px', fontWeight: '600' }}>
                最適ルート
              </h3>

              <div style={{
                padding: '16px',
                backgroundColor: '#f0fdf4',
                border: '2px solid #22c55e',
                borderRadius: '8px',
                marginBottom: '16px'
              }}>
                <div style={{ display: 'flex', gap: '24px', justifyContent: 'center' }}>
                  <div>
                    <span style={{ fontSize: '14px', color: '#6b7280' }}>総距離</span>
                    <p style={{ fontSize: '24px', fontWeight: '700', margin: '4px 0 0', color: '#166534' }}>
                      {formatDistance(optimizedRoute.totalDistanceMeters)}
                    </p>
                  </div>
                  <div>
                    <span style={{ fontSize: '14px', color: '#6b7280' }}>総所要時間</span>
                    <p style={{ fontSize: '24px', fontWeight: '700', margin: '4px 0 0', color: '#166534' }}>
                      {formatDuration(optimizedRoute.totalDurationSeconds)}
                    </p>
                  </div>
                </div>
              </div>

              <ol style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                {optimizedRoute.orderedWaypoints.map((wp, i) => (
                  <li key={i} style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '16px 0',
                    borderBottom: i < optimizedRoute.orderedWaypoints.length - 1 ? '1px solid #e5e7eb' : 'none'
                  }}>
                    <div style={{
                      width: '32px',
                      height: '32px',
                      borderRadius: '50%',
                      backgroundColor: i === 0 ? '#22c55e' : i === optimizedRoute.orderedWaypoints.length - 1 ? '#ef4444' : '#3b82f6',
                      color: 'white',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: '600',
                      flexShrink: 0
                    }}>
                      {i + 1}
                    </div>
                    <div style={{ flex: 1 }}>
                      <p style={{ margin: 0, fontWeight: '600', fontSize: '16px' }}>
                        {wp.waypoint.name || `地点 ${i + 1}`}
                      </p>
                      <p style={{ margin: '4px 0 0', fontSize: '14px', color: '#6b7280' }}>
                        {i === 0 ? '出発地点' : i === optimizedRoute.orderedWaypoints.length - 1 ? '到着地点' : '経由地点'}
                      </p>
                    </div>
                    {optimizedRoute.legs[i] && (
                      <div style={{ textAlign: 'right', fontSize: '14px', color: '#6b7280' }}>
                        <p style={{ margin: 0 }}>
                          {formatDistance(optimizedRoute.legs[i].distanceMeters)}
                        </p>
                        <p style={{ margin: '2px 0 0' }}>
                          {formatDuration(optimizedRoute.legs[i].durationSeconds)}
                        </p>
                      </div>
                    )}
                  </li>
                ))}
              </ol>
            </div>
          )}
        </div>
      )}

      {/* AI テキスト生成タブ */}
      {activeTab === 'ai' && (
        <div>
          <form onSubmit={handleAiSubmit}>
            <div style={{ marginBottom: '24px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600'
              }}>
                モデル選択:
              </label>
              <div style={{ display: 'flex', gap: '16px' }}>
                <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={enabledModels.qwen}
                    onChange={() => handleModelToggle('qwen')}
                    style={{ marginRight: '8px' }}
                  />
                  Qwen
                </label>
                <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={enabledModels.gemini}
                    onChange={() => handleModelToggle('gemini')}
                    style={{ marginRight: '8px' }}
                  />
                  Gemini
                </label>
              </div>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600'
              }}>
                メッセージ:
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="質問やプロンプトを入力してください..."
                rows={4}
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '16px',
                  border: '1px solid #ccc',
                  borderRadius: '8px',
                  resize: 'vertical',
                  fontFamily: 'inherit'
                }}
              />
            </div>

            <button
              type="submit"
              disabled={aiLoading}
              style={{
                width: '100%',
                padding: '12px 24px',
                fontSize: '16px',
                fontWeight: '600',
                backgroundColor: aiLoading ? '#ccc' : '#0070f3',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: aiLoading ? 'not-allowed' : 'pointer',
                transition: 'background-color 0.2s'
              }}
            >
              {aiLoading ? '生成中...' : '送信'}
            </button>
          </form>

          {(responses.qwen || responses.gemini) && (
            <div style={{ marginTop: '32px' }}>
              <h2 style={{
                fontSize: '24px',
                marginBottom: '16px',
                fontWeight: '600'
              }}>
                応答:
              </h2>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {responses.qwen && (
                  <div style={{
                    padding: '20px',
                    backgroundColor: '#f0f9ff',
                    borderRadius: '8px',
                    border: '2px solid #0ea5e9'
                  }}>
                    <h3 style={{
                      fontSize: '18px',
                      marginBottom: '12px',
                      fontWeight: '600',
                      color: '#0369a1'
                    }}>
                      Qwen
                    </h3>
                    <p style={{
                      whiteSpace: 'pre-wrap',
                      lineHeight: '1.6',
                      margin: 0,
                      color: '#0c4a6e'
                    }}>
                      {responses.qwen}
                    </p>
                  </div>
                )}

                {responses.gemini && (
                  <div style={{
                    padding: '20px',
                    backgroundColor: '#fef3c7',
                    borderRadius: '8px',
                    border: '2px solid #f59e0b'
                  }}>
                    <h3 style={{
                      fontSize: '18px',
                      marginBottom: '12px',
                      fontWeight: '600',
                      color: '#b45309'
                    }}>
                      Gemini
                    </h3>
                    <p style={{
                      whiteSpace: 'pre-wrap',
                      lineHeight: '1.6',
                      margin: 0,
                      color: '#78350f'
                    }}>
                      {responses.gemini}
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      {/* 地点ガイド詳細モーダル */}
      {spotModalOpen && selectedSpotIndex !== null && (
        <div
          onClick={closeSpotModal}
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '20px',
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              backgroundColor: 'white',
              borderRadius: '16px',
              maxWidth: '600px',
              width: '100%',
              maxHeight: '80vh',
              overflow: 'auto',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
            }}
          >
            {/* モーダルヘッダー */}
            <div style={{
              padding: '20px 24px',
              borderBottom: '1px solid #e5e7eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              position: 'sticky',
              top: 0,
              backgroundColor: 'white',
              borderRadius: '16px 16px 0 0',
            }}>
              <div>
                <h2 style={{ margin: 0, fontSize: '20px', fontWeight: '700' }}>
                  {aiRouteResult?.routeOptimization.orderedWaypoints?.[selectedSpotIndex]?.waypoint.name || '地点詳細'}
                </h2>
                <p style={{ margin: '4px 0 0', fontSize: '14px', color: '#6b7280' }}>
                  観光ガイドシナリオ
                </p>
              </div>
              <button
                onClick={closeSpotModal}
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '50%',
                  border: 'none',
                  backgroundColor: '#f3f4f6',
                  cursor: 'pointer',
                  fontSize: '20px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                ×
              </button>
            </div>

            {/* モーダルコンテンツ */}
            <div style={{ padding: '24px' }}>
              {(() => {
                const scenario = getSelectedSpotScenario();
                if (!scenario) {
                  return (
                    <p style={{ color: '#6b7280', textAlign: 'center' }}>
                      シナリオデータがありません
                    </p>
                  );
                }

                return (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                    {/* Qwen の結果 */}
                    {scenario.qwen && (
                      <div style={{
                        padding: '16px',
                        backgroundColor: '#f0f9ff',
                        borderRadius: '12px',
                        border: '2px solid #0ea5e9',
                      }}>
                        <h3 style={{
                          margin: '0 0 12px 0',
                          fontSize: '16px',
                          fontWeight: '600',
                          color: '#0369a1',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '8px',
                        }}>
                          <span style={{
                            display: 'inline-block',
                            width: '24px',
                            height: '24px',
                            borderRadius: '6px',
                            backgroundColor: '#0ea5e9',
                            color: 'white',
                            fontSize: '12px',
                            textAlign: 'center',
                            lineHeight: '24px',
                          }}>Q</span>
                          Qwen 生成ガイド
                        </h3>
                        <p style={{
                          margin: 0,
                          whiteSpace: 'pre-wrap',
                          lineHeight: '1.8',
                          color: '#0c4a6e',
                          fontSize: '15px',
                        }}>
                          {scenario.qwen}
                        </p>
                      </div>
                    )}

                    {/* Gemini の結果 */}
                    {scenario.gemini && (
                      <div style={{
                        padding: '16px',
                        backgroundColor: '#fef3c7',
                        borderRadius: '12px',
                        border: '2px solid #f59e0b',
                      }}>
                        <h3 style={{
                          margin: '0 0 12px 0',
                          fontSize: '16px',
                          fontWeight: '600',
                          color: '#b45309',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '8px',
                        }}>
                          <span style={{
                            display: 'inline-block',
                            width: '24px',
                            height: '24px',
                            borderRadius: '6px',
                            backgroundColor: '#f59e0b',
                            color: 'white',
                            fontSize: '12px',
                            textAlign: 'center',
                            lineHeight: '24px',
                          }}>G</span>
                          Gemini 生成ガイド
                        </h3>
                        <p style={{
                          margin: 0,
                          whiteSpace: 'pre-wrap',
                          lineHeight: '1.8',
                          color: '#78350f',
                          fontSize: '15px',
                        }}>
                          {scenario.gemini}
                        </p>
                      </div>
                    )}

                    {/* エラーがある場合 */}
                    {scenario.error && (scenario.error.qwen || scenario.error.gemini) && (
                      <div style={{
                        padding: '16px',
                        backgroundColor: '#fef2f2',
                        borderRadius: '12px',
                        border: '2px solid #fca5a5',
                      }}>
                        <h3 style={{
                          margin: '0 0 12px 0',
                          fontSize: '16px',
                          fontWeight: '600',
                          color: '#dc2626',
                        }}>
                          ⚠️ エラー
                        </h3>
                        {scenario.error.qwen && (
                          <p style={{ margin: '0 0 8px 0', color: '#991b1b' }}>
                            Qwen: {scenario.error.qwen}
                          </p>
                        )}
                        {scenario.error.gemini && (
                          <p style={{ margin: 0, color: '#991b1b' }}>
                            Gemini: {scenario.error.gemini}
                          </p>
                        )}
                      </div>
                    )}

                    {/* シナリオがない場合 */}
                    {!scenario.qwen && !scenario.gemini && (
                      <p style={{ color: '#6b7280', textAlign: 'center' }}>
                        このスポットのガイドはまだ生成されていません
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
