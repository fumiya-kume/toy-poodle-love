'use client';

import { useState } from 'react';
import {
  GeocodedPlace,
  RouteOptimizationResponse,
  OptimizedWaypoint,
  RouteLeg,
} from '../src/types/place-route';

type TabType = 'ai' | 'route';

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
  const [activeTab, setActiveTab] = useState<TabType>('route');

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
    </div>
  );
}
