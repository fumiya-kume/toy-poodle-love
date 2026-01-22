'use client';

import { useState, useRef, useCallback } from 'react';
import {
  GeocodedPlace,
  RouteOptimizationResponse,
  OptimizedWaypoint,
  RouteLeg,
} from '../src/types/place-route';
import { PipelineResponse } from '../src/types/pipeline';
import type { ExtractedLocation } from '../src/types/voice-route';

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

  // 音声入力用のstate
  const [isVoiceRecording, setIsVoiceRecording] = useState(false);
  const [voiceProcessing, setVoiceProcessing] = useState(false);
  const [audioLevel, setAudioLevel] = useState(0);
  const [voiceError, setVoiceError] = useState<string | null>(null);
  const [extractedLocation, setExtractedLocation] = useState<ExtractedLocation | null>(null);

  // 音声録音用のref
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);

  // オーディオレベル更新
  const updateAudioLevel = useCallback(() => {
    if (analyserRef.current) {
      const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount);
      analyserRef.current.getByteFrequencyData(dataArray);
      const average = dataArray.reduce((a, b) => a + b, 0) / dataArray.length;
      setAudioLevel(average / 255);
    }
    animationFrameRef.current = requestAnimationFrame(updateAudioLevel);
  }, []);

  // 音声録音開始
  const startVoiceRecording = async () => {
    try {
      setVoiceError(null);
      setExtractedLocation(null);

      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: 16000,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true,
        },
      });

      const audioContext = new AudioContext({ sampleRate: 16000 });
      audioContextRef.current = audioContext;
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      analyserRef.current = analyser;
      updateAudioLevel();

      const scriptProcessor = audioContext.createScriptProcessor(4096, 1, 1);
      const pcmChunks: Int16Array[] = [];

      scriptProcessor.onaudioprocess = (event) => {
        const inputData = event.inputBuffer.getChannelData(0);
        const pcmData = new Int16Array(inputData.length);
        for (let i = 0; i < inputData.length; i++) {
          const s = Math.max(-1, Math.min(1, inputData[i]));
          pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
        }
        pcmChunks.push(pcmData);
      };

      source.connect(scriptProcessor);
      scriptProcessor.connect(audioContext.destination);

      mediaRecorderRef.current = {
        stop: async () => {
          if (animationFrameRef.current) {
            cancelAnimationFrame(animationFrameRef.current);
          }
          setAudioLevel(0);

          scriptProcessor.disconnect();
          source.disconnect();
          stream.getTracks().forEach((track) => track.stop());

          const totalLength = pcmChunks.reduce((acc, chunk) => acc + chunk.length, 0);
          const combinedPcm = new Int16Array(totalLength);
          let offset = 0;
          for (const chunk of pcmChunks) {
            combinedPcm.set(chunk, offset);
            offset += chunk.length;
          }

          const audioBuffer = new Uint8Array(combinedPcm.buffer);
          await processVoiceAndExtract(audioBuffer);
          await audioContext.close();
        },
      } as unknown as MediaRecorder;

      setIsVoiceRecording(true);
    } catch (err) {
      console.error('Recording error:', err);
      setVoiceError(
        err instanceof Error ? err.message : 'マイクへのアクセスに失敗しました'
      );
    }
  };

  // 音声録音停止
  const stopVoiceRecording = () => {
    if (mediaRecorderRef.current && isVoiceRecording) {
      mediaRecorderRef.current.stop();
      setIsVoiceRecording(false);
    }
  };

  // 音声処理と地点抽出
  const processVoiceAndExtract = async (audioData: Uint8Array) => {
    setVoiceProcessing(true);
    try {
      // Step 1: 音声認識
      const formData = new FormData();
      const audioBlob = new Blob([audioData.buffer as ArrayBuffer], { type: 'audio/pcm' });
      formData.append('audio', audioBlob, 'recording.pcm');
      formData.append(
        'config',
        JSON.stringify({
          model: 'qwen3-asr-flash-realtime',
          sampleRate: 16000,
        })
      );

      const recognizeResponse = await fetch('/api/speech/recognize', {
        method: 'POST',
        body: formData,
      });

      const recognizeData = await recognizeResponse.json();

      if (!recognizeResponse.ok) {
        throw new Error(recognizeData.error || '音声認識に失敗しました');
      }

      const text = recognizeData.text;

      if (!text || text.trim().length === 0) {
        throw new Error('音声を認識できませんでした。もう一度話してください。');
      }

      // Step 2: LLMで地点抽出
      const extractResponse = await fetch('/api/voice-route/extract', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, model: aiRouteModel }),
      });

      const extractData = await extractResponse.json();

      if (!extractData.success) {
        throw new Error(extractData.error || '地点の抽出に失敗しました');
      }

      const location: ExtractedLocation = extractData.location;
      setExtractedLocation(location);

      // 抽出結果をフォームに反映
      if (location.origin) {
        setAiRouteStartPoint(location.origin);
      }
      if (location.destination) {
        // 目的地があれば、purposeに反映（「〜まで行きたい」形式で）
        setAiRoutePurpose(`${location.destination}まで行きたい`);
      }

    } catch (err) {
      console.error('Voice processing error:', err);
      setVoiceError(err instanceof Error ? err.message : '処理に失敗しました');
    } finally {
      setVoiceProcessing(false);
    }
  };

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
          {/* 音声入力セクション */}
          <div style={{
            marginBottom: '24px',
            padding: '20px',
            backgroundColor: '#faf5ff',
            border: '2px solid #e9d5ff',
            borderRadius: '12px',
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '12px'
            }}>
              <span style={{ fontWeight: '600', color: '#7c3aed' }}>
                🎤 音声で入力
              </span>
              <span style={{ fontSize: '14px', color: '#6b7280' }}>
                「〜から〜まで」と話してください
              </span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <button
                type="button"
                onClick={isVoiceRecording ? stopVoiceRecording : startVoiceRecording}
                disabled={voiceProcessing || aiRouteLoading}
                style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  fontSize: '24px',
                  backgroundColor: isVoiceRecording
                    ? '#ef4444'
                    : voiceProcessing
                      ? '#9ca3af'
                      : '#8b5cf6',
                  color: 'white',
                  border: 'none',
                  cursor: voiceProcessing || aiRouteLoading ? 'not-allowed' : 'pointer',
                  transition: 'all 0.2s',
                  boxShadow: isVoiceRecording
                    ? '0 0 0 4px rgba(239, 68, 68, 0.3)'
                    : '0 2px 8px rgba(0, 0, 0, 0.15)',
                }}
              >
                {voiceProcessing ? '⏳' : isVoiceRecording ? '⏹️' : '🎤'}
              </button>

              <div style={{ flex: 1 }}>
                {isVoiceRecording && (
                  <div style={{ marginBottom: '8px' }}>
                    <div style={{
                      height: '8px',
                      backgroundColor: '#e5e7eb',
                      borderRadius: '4px',
                      overflow: 'hidden',
                    }}>
                      <div style={{
                        height: '100%',
                        width: `${audioLevel * 100}%`,
                        backgroundColor: audioLevel > 0.5 ? '#22c55e' : '#f59e0b',
                        transition: 'width 0.1s',
                      }} />
                    </div>
                  </div>
                )}
                <p style={{
                  margin: 0,
                  fontSize: '14px',
                  color: '#6b7280'
                }}>
                  {voiceProcessing ? '音声を処理中...' :
                   isVoiceRecording ? '話し終わったらボタンを押してください' :
                   'ボタンを押して話しかけてください'}
                </p>
              </div>
            </div>

            {/* 音声エラー */}
            {voiceError && (
              <div style={{
                marginTop: '12px',
                padding: '8px 12px',
                backgroundColor: '#fef2f2',
                border: '1px solid #fecaca',
                borderRadius: '6px',
                color: '#dc2626',
                fontSize: '14px'
              }}>
                {voiceError}
              </div>
            )}

            {/* 抽出結果表示 */}
            {extractedLocation && (
              <div style={{
                marginTop: '12px',
                padding: '12px',
                backgroundColor: 'white',
                borderRadius: '8px',
                border: '1px solid #e9d5ff'
              }}>
                <p style={{ margin: '0 0 8px', fontSize: '14px', fontWeight: '600', color: '#7c3aed' }}>
                  📍 認識結果:
                </p>
                <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
                  {extractedLocation.origin && (
                    <span style={{
                      padding: '4px 8px',
                      backgroundColor: '#dcfce7',
                      color: '#166534',
                      borderRadius: '4px',
                      fontSize: '14px'
                    }}>
                      出発: {extractedLocation.origin}
                    </span>
                  )}
                  {extractedLocation.destination && (
                    <span style={{
                      padding: '4px 8px',
                      backgroundColor: '#fee2e2',
                      color: '#991b1b',
                      borderRadius: '4px',
                      fontSize: '14px'
                    }}>
                      目的地: {extractedLocation.destination}
                    </span>
                  )}
                </div>
                {extractedLocation.interpretation && (
                  <p style={{ margin: '8px 0 0', fontSize: '12px', color: '#6b7280', fontStyle: 'italic' }}>
                    💭 {extractedLocation.interpretation}
                  </p>
                )}
              </div>
            )}
          </div>

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
                disabled={isVoiceRecording || voiceProcessing}
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '16px',
                  border: '1px solid #ccc',
                  borderRadius: '8px',
                  fontFamily: 'inherit',
                  backgroundColor: isVoiceRecording || voiceProcessing ? '#f3f4f6' : 'white'
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
                disabled={isVoiceRecording || voiceProcessing}
                style={{
                  width: '100%',
                  padding: '12px',
                  fontSize: '16px',
                  border: '1px solid #ccc',
                  borderRadius: '8px',
                  fontFamily: 'inherit',
                  backgroundColor: isVoiceRecording || voiceProcessing ? '#f3f4f6' : 'white'
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
              disabled={aiRouteLoading}
              style={{
                width: '100%',
                padding: '12px 24px',
                fontSize: '16px',
                fontWeight: '600',
                backgroundColor: aiRouteLoading ? '#ccc' : '#8b5cf6',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: aiRouteLoading ? 'not-allowed' : 'pointer',
                transition: 'background-color 0.2s'
              }}
            >
              {aiRouteLoading ? '処理中...' : 'AI でルートを生成・最適化'}
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
          {aiRouteLoading && (
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
                    backgroundColor: '#f59e0b',
                    animation: 'pulse 1s infinite'
                  }} />
                  <span>1. AIがルートを生成中...</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: '#9ca3af'
                  }} />
                  <span style={{ color: '#9ca3af' }}>2. 座標を取得</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{
                    width: '12px',
                    height: '12px',
                    borderRadius: '50%',
                    backgroundColor: '#9ca3af'
                  }} />
                  <span style={{ color: '#9ca3af' }}>3. ルートを最適化</span>
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
                  <h3 style={{ fontSize: '20px', marginBottom: '16px', fontWeight: '600' }}>
                    最適化されたルート
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

                  <ol style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                    {aiRouteResult.routeOptimization.orderedWaypoints.map((wp, i) => (
                      <li key={i} style={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '12px',
                        padding: '16px 0',
                        borderBottom: i < aiRouteResult.routeOptimization.orderedWaypoints!.length - 1 ? '1px solid #e5e7eb' : 'none'
                      }}>
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
                          <p style={{ margin: 0, fontWeight: '600', fontSize: '16px' }}>
                            {wp.waypoint.name || `地点 ${i + 1}`}
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
                    ))}
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
    </div>
  );
}
