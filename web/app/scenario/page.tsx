'use client';

import { useState, useRef, useEffect } from 'react';
import { RouteInput, RouteSpot, ScenarioOutput, SpotType, ScenarioIntegrationOutput } from '../../src/types/scenario';
import { predefinedRoutes, getRouteById } from '../../src/data/routes';

interface SpotFormData extends RouteSpot {
  id: string;
}

interface ImportSpot {
  name: string;
  address?: string;
  latitude?: number;
  longitude?: number;
}

export default function ScenarioPage() {
  const [routeName, setRouteName] = useState('Tokyo Station → Asakusa Course');
  const [spots, setSpots] = useState<SpotFormData[]>(() => {
    // Load the default Tokyo Station route
    const defaultRoute = getRouteById('tokyo-station-asakusa');
    if (defaultRoute) {
      return defaultRoute.spots.map((spot, index) => ({
        ...spot,
        id: String(index + 1),
      }));
    }
    return [];
  });

  const loadPredefinedRoute = (routeId: string) => {
    const route = getRouteById(routeId);
    if (route) {
      setRouteName(route.routeName);
      setSpots(route.spots.map((spot, index) => ({
        ...spot,
        id: Date.now().toString() + index,
      })));
    }
  };
  const [jsonInput, setJsonInput] = useState('');
  const [showJsonInput, setShowJsonInput] = useState(false);
  const [result, setResult] = useState<ScenarioOutput | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 統合機能の状態
  const [integrating, setIntegrating] = useState(false);
  const [integrationResult, setIntegrationResult] = useState<ScenarioIntegrationOutput | null>(null);
  const [integrationError, setIntegrationError] = useState<string | null>(null);
  const [selectedSourceModel, setSelectedSourceModel] = useState<'qwen' | 'gemini'>('qwen');
  const [selectedIntegrationLLM, setSelectedIntegrationLLM] = useState<'qwen' | 'gemini'>('gemini');
  const abortControllerRef = useRef<AbortController | null>(null);

  const addSpot = () => {
    const newSpot: SpotFormData = {
      id: Date.now().toString(),
      name: '',
      type: 'waypoint',
      description: '',
      point: '',
    };
    setSpots([...spots, newSpot]);
  };

  const removeSpot = (id: string) => {
    setSpots(spots.filter(spot => spot.id !== id));
  };

  const updateSpot = (id: string, field: keyof SpotFormData, value: string) => {
    setSpots(spots.map(spot =>
      spot.id === id ? { ...spot, [field]: value } : spot
    ));
  };

  const importFromJson = () => {
    try {
      const parsed = JSON.parse(jsonInput) as ImportSpot[];

      if (!Array.isArray(parsed) || parsed.length === 0) {
        alert('JSONは配列形式で、少なくとも1つの地点が必要です');
        return;
      }

      const convertedSpots: SpotFormData[] = parsed.map((spot, index) => {
        // 名前から（スタート）や（ゴール）を削除してtypeを判定
        let name = spot.name;
        let type: SpotType = 'waypoint';

        if (name.includes('スタート') || name.includes('START') || index === 0) {
          type = 'start';
          name = name.replace(/[（(]スタート[）)]|[（(]START[）)]/gi, '').trim();
        } else if (name.includes('ゴール') || name.includes('GOAL') || index === parsed.length - 1) {
          type = 'destination';
          name = name.replace(/[（(]ゴール[）)]|[（(]GOAL[）)]/gi, '').trim();
        }

        return {
          id: Date.now().toString() + index,
          name,
          type,
          description: spot.address || '',
          point: '',
        };
      });

      setSpots(convertedSpots);

      // ルート名を自動生成（最初と最後の地点から）
      if (convertedSpots.length >= 2) {
        const firstName = convertedSpots[0].name;
        const lastName = convertedSpots[convertedSpots.length - 1].name;
        setRouteName(`${firstName}→${lastName}コース`);
      }

      setShowJsonInput(false);
      setJsonInput('');
      alert(`${convertedSpots.length}件の地点をインポートしました`);
    } catch (err) {
      alert('JSONのパースに失敗しました: ' + String(err));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!routeName.trim()) {
      alert('ルート名を入力してください');
      return;
    }

    if (spots.length === 0) {
      alert('少なくとも1つの地点を追加してください');
      return;
    }

    setLoading(true);
    setError(null);
    setResult(null);

    const routeInput: RouteInput = {
      routeName,
      spots: spots.map(({ id, ...spot }) => spot),
    };

    try {
      const response = await fetch('/api/scenario', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ route: routeInput, models: 'both' }),
      });

      const data = await response.json();

      if (data.success && data.data) {
        setResult(data.data);
      } else {
        setError(data.error || 'シナリオ生成に失敗しました');
      }
    } catch (err) {
      setError('API呼び出しエラー: ' + String(err));
    } finally {
      setLoading(false);
    }
  };

  // 統合処理ハンドラー
  const handleIntegrate = async () => {
    if (!result || !result.spots || result.spots.length === 0) {
      alert('統合するシナリオがありません。まずシナリオを生成してください');
      return;
    }

    // 前のリクエストをキャンセル
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // 新しいAbortControllerを作成
    const abortController = new AbortController();
    abortControllerRef.current = abortController;

    setIntegrating(true);
    setIntegrationError(null);
    setIntegrationResult(null);

    try {
      const response = await fetch('/api/scenario/integrate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          integration: {
            routeName: result.routeName,
            spots: result.spots,
            sourceModel: selectedSourceModel,
            integrationLLM: selectedIntegrationLLM,
          },
        }),
        signal: abortController.signal,
      });

      const data = await response.json();

      if (data.success && data.data) {
        setIntegrationResult(data.data);
      } else {
        setIntegrationError(data.error || 'シナリオ統合に失敗しました');
      }
    } catch (err: unknown) {
      if (err instanceof Error && err.name === 'AbortError') {
        // キャンセルされた場合は何もしない
        return;
      }
      setIntegrationError('API呼び出しエラー: ' + String(err));
    } finally {
      setIntegrating(false);
      abortControllerRef.current = null;
    }
  };

  // アンマウント時にクリーンアップ
  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, []);

  return (
    <div style={{
      maxWidth: '1200px',
      margin: '0 auto',
      padding: '40px 20px',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    }}>
      <h1 style={{ fontSize: '32px', marginBottom: '8px', textAlign: 'center' }}>
        タクシー観光ガイドシナリオ生成
      </h1>
      <p style={{ textAlign: 'center', color: '#666', marginBottom: '32px' }}>
        タクシールートの地点情報を入力して、ドライバーが話す観光ガイドのセリフを生成します
      </p>

      <form onSubmit={handleSubmit}>
        {/* Predefined Route Selector */}
        <div style={{ marginBottom: '24px' }}>
          <label style={{
            display: 'block',
            marginBottom: '8px',
            fontWeight: '600'
          }}>
            Load Predefined Route:
          </label>
          <select
            onChange={(e) => {
              if (e.target.value) {
                loadPredefinedRoute(e.target.value);
              }
            }}
            style={{
              width: '100%',
              padding: '12px',
              fontSize: '16px',
              border: '1px solid #ccc',
              borderRadius: '8px',
              backgroundColor: 'white',
              cursor: 'pointer',
            }}
            defaultValue=""
          >
            <option value="" disabled>-- Select a predefined route --</option>
            {predefinedRoutes.map(route => (
              <option key={route.id} value={route.id}>
                {route.routeName} - {route.description}
              </option>
            ))}
          </select>
        </div>

        {/* Route Name Input */}
        <div style={{ marginBottom: '24px' }}>
          <label style={{
            display: 'block',
            marginBottom: '8px',
            fontWeight: '600'
          }}>
            Route Name:
          </label>
          <input
            type="text"
            value={routeName}
            onChange={(e) => setRouteName(e.target.value)}
            placeholder="e.g. Tokyo Station → Asakusa Course"
            style={{
              width: '100%',
              padding: '12px',
              fontSize: '16px',
              border: '1px solid #ccc',
              borderRadius: '8px',
            }}
          />
        </div>

        {/* JSON入力セクション */}
        <div style={{ marginBottom: '24px' }}>
          <button
            type="button"
            onClick={() => setShowJsonInput(!showJsonInput)}
            style={{
              padding: '10px 20px',
              backgroundColor: '#8b5cf6',
              color: 'white',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontSize: '14px',
              fontWeight: '600',
              marginBottom: showJsonInput ? '12px' : '0',
            }}
          >
            {showJsonInput ? 'JSON入力を閉じる' : 'JSONから地点をインポート'}
          </button>

          {showJsonInput && (
            <div style={{
              padding: '16px',
              backgroundColor: '#f9fafb',
              borderRadius: '8px',
              border: '1px solid #e5e7eb',
            }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#374151',
              }}>
                JSON配列を貼り付け:
              </label>
              <p style={{ fontSize: '12px', color: '#6b7280', marginBottom: '8px' }}>
                例: [&#123;"name": "東京駅（スタート）", "address": "..."&#125;, ...]
              </p>
              <textarea
                value={jsonInput}
                onChange={(e) => setJsonInput(e.target.value)}
                placeholder='[{"name": "東京駅（スタート）", "address": "東京都千代田区丸の内1丁目", "latitude": 35.681236, "longitude": 139.767125}, ...]'
                rows={8}
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '14px',
                  border: '1px solid #d1d5db',
                  borderRadius: '6px',
                  fontFamily: 'monospace',
                  resize: 'vertical',
                  marginBottom: '12px',
                }}
              />
              <button
                type="button"
                onClick={importFromJson}
                style={{
                  padding: '8px 16px',
                  backgroundColor: '#059669',
                  color: 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: '600',
                }}
              >
                インポート
              </button>
            </div>
          )}
        </div>

        {/* 地点リスト */}
        <div style={{ marginBottom: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <label style={{ fontWeight: '600' }}>地点リスト:</label>
            <button
              type="button"
              onClick={addSpot}
              style={{
                padding: '8px 16px',
                backgroundColor: '#10b981',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: '600',
              }}
            >
              + 地点を追加
            </button>
          </div>

          {spots.map((spot, index) => (
            <div key={spot.id} style={{
              padding: '16px',
              marginBottom: '12px',
              backgroundColor: '#f9fafb',
              borderRadius: '8px',
              border: '1px solid #e5e7eb',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <span style={{ fontWeight: '600', color: '#374151' }}>地点 {index + 1}</span>
                <button
                  type="button"
                  onClick={() => removeSpot(spot.id)}
                  style={{
                    padding: '4px 12px',
                    backgroundColor: '#ef4444',
                    color: 'white',
                    border: 'none',
                    borderRadius: '4px',
                    cursor: 'pointer',
                    fontSize: '12px',
                  }}
                >
                  削除
                </button>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '14px', marginBottom: '4px', color: '#6b7280' }}>
                    地点名 *
                  </label>
                  <input
                    type="text"
                    value={spot.name}
                    onChange={(e) => updateSpot(spot.id, 'name', e.target.value)}
                    placeholder="例: 皇居外苑"
                    style={{
                      width: '100%',
                      padding: '8px',
                      fontSize: '14px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '14px', marginBottom: '4px', color: '#6b7280' }}>
                    タイプ *
                  </label>
                  <select
                    value={spot.type}
                    onChange={(e) => updateSpot(spot.id, 'type', e.target.value)}
                    style={{
                      width: '100%',
                      padding: '8px',
                      fontSize: '14px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                    }}
                  >
                    <option value="start">出発地</option>
                    <option value="waypoint">経由地</option>
                    <option value="destination">目的地</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '14px', marginBottom: '4px', color: '#6b7280' }}>
                    説明
                  </label>
                  <input
                    type="text"
                    value={spot.description || ''}
                    onChange={(e) => updateSpot(spot.id, 'description', e.target.value)}
                    placeholder="例: 皇居の外苑エリア"
                    style={{
                      width: '100%',
                      padding: '8px',
                      fontSize: '14px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '14px', marginBottom: '4px', color: '#6b7280' }}>
                    観光ポイント
                  </label>
                  <input
                    type="text"
                    value={spot.point || ''}
                    onChange={(e) => updateSpot(spot.id, 'point', e.target.value)}
                    placeholder="例: 二重橋前。松の緑が美しい"
                    style={{
                      width: '100%',
                      padding: '8px',
                      fontSize: '14px',
                      border: '1px solid #d1d5db',
                      borderRadius: '6px',
                    }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* 送信ボタン */}
        <button
          type="submit"
          disabled={loading}
          style={{
            width: '100%',
            padding: '14px 24px',
            fontSize: '18px',
            fontWeight: '600',
            backgroundColor: loading ? '#9ca3af' : '#3b82f6',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: loading ? 'not-allowed' : 'pointer',
          }}
        >
          {loading ? 'シナリオ生成中...' : 'シナリオを生成'}
        </button>
      </form>

      {/* エラー表示 */}
      {error && (
        <div style={{
          marginTop: '24px',
          padding: '16px',
          backgroundColor: '#fee2e2',
          border: '2px solid #ef4444',
          borderRadius: '8px',
          color: '#991b1b',
        }}>
          <strong>エラー:</strong> {error}
        </div>
      )}

      {/* 結果表示 */}
      {result && (
        <div style={{ marginTop: '32px' }}>
          <h2 style={{ fontSize: '24px', marginBottom: '16px', fontWeight: '600' }}>
            生成結果
          </h2>

          {/* 統計情報 */}
          <div style={{
            padding: '16px',
            marginBottom: '24px',
            backgroundColor: '#f0f9ff',
            borderRadius: '8px',
            border: '1px solid #bae6fd',
          }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', fontSize: '14px' }}>
              <div>
                <div style={{ color: '#0369a1', fontWeight: '600', marginBottom: '4px' }}>処理時間</div>
                <div style={{ fontSize: '18px', fontWeight: '700', color: '#0c4a6e' }}>
                  {result.stats.processingTimeMs}ms
                </div>
              </div>
              <div>
                <div style={{ color: '#0369a1', fontWeight: '600', marginBottom: '4px' }}>Qwen成功</div>
                <div style={{ fontSize: '18px', fontWeight: '700', color: '#0c4a6e' }}>
                  {result.stats.successCount.qwen}/{result.stats.totalSpots}
                </div>
              </div>
              <div>
                <div style={{ color: '#0369a1', fontWeight: '600', marginBottom: '4px' }}>Gemini成功</div>
                <div style={{ fontSize: '18px', fontWeight: '700', color: '#0c4a6e' }}>
                  {result.stats.successCount.gemini}/{result.stats.totalSpots}
                </div>
              </div>
            </div>
          </div>

          {/* 各地点のシナリオ */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {result.spots.map((spot, index) => (
              <div key={index} style={{
                padding: '20px',
                backgroundColor: '#ffffff',
                borderRadius: '8px',
                border: '2px solid #e5e7eb',
              }}>
                <h3 style={{
                  fontSize: '20px',
                  marginBottom: '16px',
                  fontWeight: '600',
                  color: '#111827',
                  borderBottom: '2px solid #e5e7eb',
                  paddingBottom: '8px',
                }}>
                  {spot.name} ({spot.type === 'start' ? '出発地' : spot.type === 'waypoint' ? '経由地' : '目的地'})
                </h3>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  {/* Qwen結果 */}
                  <div style={{
                    padding: '16px',
                    backgroundColor: '#f0f9ff',
                    borderRadius: '6px',
                    border: '1px solid #0ea5e9',
                  }}>
                    <h4 style={{
                      fontSize: '16px',
                      marginBottom: '8px',
                      fontWeight: '600',
                      color: '#0369a1',
                    }}>
                      Qwen
                    </h4>
                    <p style={{
                      whiteSpace: 'pre-wrap',
                      lineHeight: '1.6',
                      margin: 0,
                      color: spot.qwen ? '#0c4a6e' : '#ef4444',
                      fontSize: '14px',
                    }}>
                      {spot.qwen || (spot.error?.qwen ? `エラー: ${spot.error.qwen}` : '結果なし')}
                    </p>
                  </div>

                  {/* Gemini結果 */}
                  <div style={{
                    padding: '16px',
                    backgroundColor: '#fef3c7',
                    borderRadius: '6px',
                    border: '1px solid #f59e0b',
                  }}>
                    <h4 style={{
                      fontSize: '16px',
                      marginBottom: '8px',
                      fontWeight: '600',
                      color: '#b45309',
                    }}>
                      Gemini
                    </h4>
                    <p style={{
                      whiteSpace: 'pre-wrap',
                      lineHeight: '1.6',
                      margin: 0,
                      color: spot.gemini ? '#78350f' : '#ef4444',
                      fontSize: '14px',
                    }}>
                      {spot.gemini || (spot.error?.gemini ? `エラー: ${spot.error.gemini}` : '結果なし')}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* 統合セクション */}
          <div style={{
            marginTop: '32px',
            padding: '24px',
            backgroundColor: '#faf5ff',
            borderRadius: '8px',
            border: '2px solid #a855f7',
          }}>
            <h2 style={{ fontSize: '24px', marginBottom: '16px', fontWeight: '600', color: '#7e22ce' }}>
              シナリオ統合
            </h2>
            <p style={{ fontSize: '14px', color: '#6b21a8', marginBottom: '16px' }}>
              生成されたシナリオを1つの自然な流れのテキストに統合します
            </p>

            {/* 統合設定 */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
              <div>
                <label style={{
                  display: 'block',
                  fontSize: '14px',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#6b21a8',
                }}>
                  使用するシナリオ:
                </label>
                <select
                  value={selectedSourceModel}
                  onChange={(e) => setSelectedSourceModel(e.target.value as 'qwen' | 'gemini')}
                  disabled={integrating}
                  style={{
                    width: '100%',
                    padding: '10px',
                    fontSize: '14px',
                    border: '1px solid #d8b4fe',
                    borderRadius: '6px',
                    backgroundColor: 'white',
                    cursor: integrating ? 'not-allowed' : 'pointer',
                  }}
                >
                  <option value="qwen">Qwen</option>
                  <option value="gemini">Gemini</option>
                </select>
              </div>

              <div>
                <label style={{
                  display: 'block',
                  fontSize: '14px',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#6b21a8',
                }}>
                  統合に使用するLLM:
                </label>
                <select
                  value={selectedIntegrationLLM}
                  onChange={(e) => setSelectedIntegrationLLM(e.target.value as 'qwen' | 'gemini')}
                  disabled={integrating}
                  style={{
                    width: '100%',
                    padding: '10px',
                    fontSize: '14px',
                    border: '1px solid #d8b4fe',
                    borderRadius: '6px',
                    backgroundColor: 'white',
                    cursor: integrating ? 'not-allowed' : 'pointer',
                  }}
                >
                  <option value="gemini">Gemini</option>
                  <option value="qwen">Qwen</option>
                </select>
              </div>
            </div>

            {/* 統合ボタン */}
            <button
              onClick={handleIntegrate}
              disabled={integrating}
              style={{
                width: '100%',
                padding: '12px 24px',
                fontSize: '16px',
                fontWeight: '600',
                backgroundColor: integrating ? '#9ca3af' : '#a855f7',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: integrating ? 'not-allowed' : 'pointer',
                marginBottom: '16px',
              }}
            >
              {integrating ? '統合中...' : 'シナリオを統合'}
            </button>

            {/* 統合エラー表示 */}
            {integrationError && (
              <div style={{
                padding: '16px',
                backgroundColor: '#fee2e2',
                border: '2px solid #ef4444',
                borderRadius: '8px',
                color: '#991b1b',
                marginBottom: '16px',
              }}>
                <strong>エラー:</strong> {integrationError}
              </div>
            )}

            {/* 統合結果表示 */}
            {integrationResult && (
              <div style={{
                padding: '20px',
                backgroundColor: 'white',
                borderRadius: '8px',
                border: '2px solid #d8b4fe',
              }}>
                <h3 style={{
                  fontSize: '18px',
                  marginBottom: '12px',
                  fontWeight: '600',
                  color: '#7e22ce',
                }}>
                  統合されたシナリオ
                </h3>
                <div style={{
                  fontSize: '12px',
                  color: '#9333ea',
                  marginBottom: '12px',
                  display: 'flex',
                  gap: '16px',
                }}>
                  <span>ソース: {integrationResult.sourceModel === 'qwen' ? 'Qwen' : 'Gemini'}</span>
                  <span>統合LLM: {integrationResult.integrationLLM === 'qwen' ? 'Qwen' : 'Gemini'}</span>
                  <span>処理時間: {integrationResult.processingTimeMs}ms</span>
                </div>
                <div style={{
                  whiteSpace: 'pre-wrap',
                  lineHeight: '1.8',
                  fontSize: '15px',
                  color: '#1f2937',
                  padding: '16px',
                  backgroundColor: '#f9fafb',
                  borderRadius: '6px',
                  border: '1px solid #e5e7eb',
                }}>
                  {integrationResult.integratedScript}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
