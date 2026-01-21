'use client';

import { useState, useRef, useCallback } from 'react';
import type { VoiceRouteSearchResponse, ExtractedLocation } from '../../src/types/voice-route';
import type { GeocodedPlace, RouteLeg } from '../../src/types/place-route';

type SearchState = 'idle' | 'recording' | 'processing' | 'extracting' | 'searching' | 'done';

export default function VoiceRoutePage() {
  // 状態管理
  const [searchState, setSearchState] = useState<SearchState>('idle');
  const [transcribedText, setTranscribedText] = useState('');
  const [extractedLocation, setExtractedLocation] = useState<ExtractedLocation | null>(null);
  const [geocodedPlaces, setGeocodedPlaces] = useState<{
    origin?: GeocodedPlace;
    destination?: GeocodedPlace;
    waypoints?: GeocodedPlace[];
  } | null>(null);
  const [route, setRoute] = useState<{
    totalDistanceMeters: number;
    totalDurationSeconds: number;
    legs: RouteLeg[];
  } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [audioLevel, setAudioLevel] = useState(0);
  const [model, setModel] = useState<'qwen' | 'gemini'>('gemini');

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

  // 録音開始
  const startRecording = async () => {
    try {
      setError(null);
      setTranscribedText('');
      setExtractedLocation(null);
      setGeocodedPlaces(null);
      setRoute(null);

      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: 16000,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true,
        },
      });

      // オーディオレベルメーター用
      const audioContext = new AudioContext({ sampleRate: 16000 });
      audioContextRef.current = audioContext;
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      analyserRef.current = analyser;
      updateAudioLevel();

      // PCM16データを収集
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
          // アニメーション停止
          if (animationFrameRef.current) {
            cancelAnimationFrame(animationFrameRef.current);
          }
          setAudioLevel(0);

          // 音声処理停止
          scriptProcessor.disconnect();
          source.disconnect();
          stream.getTracks().forEach((track) => track.stop());

          // PCMデータを結合
          const totalLength = pcmChunks.reduce((acc, chunk) => acc + chunk.length, 0);
          const combinedPcm = new Int16Array(totalLength);
          let offset = 0;
          for (const chunk of pcmChunks) {
            combinedPcm.set(chunk, offset);
            offset += chunk.length;
          }

          const audioBuffer = new Uint8Array(combinedPcm.buffer);
          await processAudioAndSearch(audioBuffer);
          await audioContext.close();
        },
      } as unknown as MediaRecorder;

      setSearchState('recording');
    } catch (err) {
      console.error('Recording error:', err);
      setError(
        err instanceof Error ? err.message : 'マイクへのアクセスに失敗しました'
      );
      setSearchState('idle');
    }
  };

  // 録音停止
  const stopRecording = () => {
    if (mediaRecorderRef.current && searchState === 'recording') {
      mediaRecorderRef.current.stop();
      setSearchState('processing');
    }
  };

  // 音声処理とルート検索
  const processAudioAndSearch = async (audioData: Uint8Array) => {
    try {
      // Step 1: 音声認識
      setSearchState('processing');
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
      setTranscribedText(text);

      if (!text || text.trim().length === 0) {
        throw new Error('音声を認識できませんでした。もう一度話してください。');
      }

      // Step 2: 地点抽出とルート検索
      setSearchState('searching');
      const searchResponse = await fetch('/api/voice-route/search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, model }),
      });

      const searchData: VoiceRouteSearchResponse = await searchResponse.json();

      if (searchData.extractedLocation) {
        setExtractedLocation(searchData.extractedLocation);
      }

      if (searchData.geocodedPlaces) {
        setGeocodedPlaces(searchData.geocodedPlaces);
      }

      if (searchData.route) {
        setRoute(searchData.route);
      }

      if (!searchData.success && searchData.error) {
        setError(searchData.error);
      }

      setSearchState('done');
    } catch (err) {
      console.error('Processing error:', err);
      setError(err instanceof Error ? err.message : '処理に失敗しました');
      setSearchState('done');
    }
  };

  // テキスト入力でルート検索（デバッグ/テスト用）
  const handleTextSearch = async () => {
    if (!transcribedText.trim()) {
      setError('テキストを入力してください');
      return;
    }

    setError(null);
    setExtractedLocation(null);
    setGeocodedPlaces(null);
    setRoute(null);
    setSearchState('searching');

    try {
      const searchResponse = await fetch('/api/voice-route/search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: transcribedText, model }),
      });

      const searchData: VoiceRouteSearchResponse = await searchResponse.json();

      if (searchData.extractedLocation) {
        setExtractedLocation(searchData.extractedLocation);
      }

      if (searchData.geocodedPlaces) {
        setGeocodedPlaces(searchData.geocodedPlaces);
      }

      if (searchData.route) {
        setRoute(searchData.route);
      }

      if (!searchData.success && searchData.error) {
        setError(searchData.error);
      }

      setSearchState('done');
    } catch (err) {
      console.error('Search error:', err);
      setError(err instanceof Error ? err.message : '検索に失敗しました');
      setSearchState('done');
    }
  };

  // フォーマット関数
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

  // リセット
  const handleReset = () => {
    setSearchState('idle');
    setTranscribedText('');
    setExtractedLocation(null);
    setGeocodedPlaces(null);
    setRoute(null);
    setError(null);
  };

  const isProcessing = searchState === 'processing' || searchState === 'extracting' || searchState === 'searching';

  return (
    <div style={{
      maxWidth: '800px',
      margin: '0 auto',
      padding: '40px 20px',
      fontFamily: 'system-ui, -apple-system, sans-serif'
    }}>
      <h1 style={{ fontSize: '32px', marginBottom: '8px', textAlign: 'center' }}>
        🎤 音声ルート検索
      </h1>
      <p style={{ textAlign: 'center', color: '#6b7280', marginBottom: '32px' }}>
        話しかけるだけでルート検索！「〜から〜まで」と話してください
      </p>

      {/* モデル選択 */}
      <div style={{ marginBottom: '24px' }}>
        <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600' }}>
          AIモデル:
        </label>
        <select
          value={model}
          onChange={(e) => setModel(e.target.value as 'qwen' | 'gemini')}
          disabled={isProcessing || searchState === 'recording'}
          style={{
            width: '200px',
            padding: '8px 12px',
            fontSize: '16px',
            border: '1px solid #ccc',
            borderRadius: '8px',
            backgroundColor: 'white'
          }}
        >
          <option value="gemini">Gemini</option>
          <option value="qwen">Qwen</option>
        </select>
      </div>

      {/* 録音ボタン */}
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        marginBottom: '24px'
      }}>
        <button
          onClick={searchState === 'recording' ? stopRecording : startRecording}
          disabled={isProcessing}
          style={{
            width: '160px',
            height: '160px',
            borderRadius: '50%',
            fontSize: '24px',
            fontWeight: '600',
            backgroundColor: searchState === 'recording'
              ? '#ef4444'
              : isProcessing
                ? '#9ca3af'
                : '#3b82f6',
            color: 'white',
            border: 'none',
            cursor: isProcessing ? 'not-allowed' : 'pointer',
            transition: 'all 0.2s',
            boxShadow: searchState === 'recording'
              ? '0 0 0 8px rgba(239, 68, 68, 0.3)'
              : '0 4px 12px rgba(0, 0, 0, 0.15)',
          }}
        >
          {searchState === 'recording' ? '🛑 停止' :
           isProcessing ? '⏳ 処理中' : '🎤 話す'}
        </button>

        {/* 状態メッセージ */}
        <p style={{
          marginTop: '16px',
          fontSize: '16px',
          color: '#6b7280',
          textAlign: 'center'
        }}>
          {searchState === 'idle' && 'ボタンを押して話しかけてください'}
          {searchState === 'recording' && '話し終わったらボタンを押してください'}
          {searchState === 'processing' && '音声を認識しています...'}
          {searchState === 'extracting' && '地点を抽出しています...'}
          {searchState === 'searching' && 'ルートを検索しています...'}
          {searchState === 'done' && (error ? 'エラーが発生しました' : '検索完了！')}
        </p>
      </div>

      {/* オーディオレベル */}
      {searchState === 'recording' && (
        <div style={{ marginBottom: '24px' }}>
          <div style={{
            height: '12px',
            backgroundColor: '#e5e7eb',
            borderRadius: '6px',
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

      {/* テキスト入力（デバッグ/テスト用） */}
      <div style={{
        marginBottom: '24px',
        padding: '16px',
        backgroundColor: '#f9fafb',
        borderRadius: '8px'
      }}>
        <label style={{ display: 'block', marginBottom: '8px', fontWeight: '600' }}>
          テキストで検索（テスト用）:
        </label>
        <div style={{ display: 'flex', gap: '8px' }}>
          <input
            type="text"
            value={transcribedText}
            onChange={(e) => setTranscribedText(e.target.value)}
            placeholder="例: 東京駅から渋谷駅まで行きたい"
            disabled={isProcessing || searchState === 'recording'}
            style={{
              flex: 1,
              padding: '12px',
              fontSize: '16px',
              border: '1px solid #ccc',
              borderRadius: '8px',
            }}
          />
          <button
            onClick={handleTextSearch}
            disabled={isProcessing || searchState === 'recording' || !transcribedText.trim()}
            style={{
              padding: '12px 24px',
              fontSize: '16px',
              fontWeight: '600',
              backgroundColor: isProcessing || !transcribedText.trim() ? '#ccc' : '#10b981',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: isProcessing || !transcribedText.trim() ? 'not-allowed' : 'pointer',
            }}
          >
            検索
          </button>
        </div>
      </div>

      {/* エラー表示 */}
      {error && (
        <div style={{
          marginBottom: '24px',
          padding: '16px',
          backgroundColor: '#fef2f2',
          border: '1px solid #fecaca',
          borderRadius: '8px',
          color: '#dc2626'
        }}>
          {error}
        </div>
      )}

      {/* 認識テキスト */}
      {transcribedText && searchState === 'done' && (
        <div style={{
          marginBottom: '24px',
          padding: '16px',
          backgroundColor: '#f0f9ff',
          border: '1px solid #bae6fd',
          borderRadius: '8px'
        }}>
          <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '8px', color: '#0369a1' }}>
            📝 認識されたテキスト
          </h3>
          <p style={{ margin: 0, fontSize: '16px', color: '#0c4a6e' }}>
            「{transcribedText}」
          </p>
        </div>
      )}

      {/* 抽出された地点 */}
      {extractedLocation && (
        <div style={{
          marginBottom: '24px',
          padding: '16px',
          backgroundColor: '#faf5ff',
          border: '1px solid #e9d5ff',
          borderRadius: '8px'
        }}>
          <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '12px', color: '#7c3aed' }}>
            📍 抽出された地点
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{
                padding: '4px 8px',
                backgroundColor: '#22c55e',
                color: 'white',
                borderRadius: '4px',
                fontSize: '12px',
                fontWeight: '600'
              }}>
                出発
              </span>
              <span>{extractedLocation.origin || '（不明）'}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{
                padding: '4px 8px',
                backgroundColor: '#ef4444',
                color: 'white',
                borderRadius: '4px',
                fontSize: '12px',
                fontWeight: '600'
              }}>
                目的地
              </span>
              <span>{extractedLocation.destination || '（不明）'}</span>
            </div>
            {extractedLocation.waypoints.length > 0 && (
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px' }}>
                <span style={{
                  padding: '4px 8px',
                  backgroundColor: '#3b82f6',
                  color: 'white',
                  borderRadius: '4px',
                  fontSize: '12px',
                  fontWeight: '600'
                }}>
                  経由
                </span>
                <span>{extractedLocation.waypoints.join(' → ')}</span>
              </div>
            )}
          </div>
          <p style={{ marginTop: '12px', fontSize: '14px', color: '#6b7280' }}>
            信頼度: {Math.round(extractedLocation.confidence * 100)}%
          </p>
          {extractedLocation.interpretation && (
            <p style={{ marginTop: '4px', fontSize: '14px', color: '#6b7280', fontStyle: 'italic' }}>
              💭 {extractedLocation.interpretation}
            </p>
          )}
        </div>
      )}

      {/* ルート結果 */}
      {route && (
        <div style={{ marginBottom: '24px' }}>
          <h3 style={{ fontSize: '20px', fontWeight: '600', marginBottom: '16px' }}>
            🚗 ルート検索結果
          </h3>

          {/* 総距離・時間 */}
          <div style={{
            padding: '16px',
            backgroundColor: '#f0fdf4',
            border: '2px solid #22c55e',
            borderRadius: '8px',
            marginBottom: '16px'
          }}>
            <div style={{ display: 'flex', gap: '32px', justifyContent: 'center' }}>
              <div style={{ textAlign: 'center' }}>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>総距離</span>
                <p style={{ fontSize: '28px', fontWeight: '700', margin: '4px 0 0', color: '#166534' }}>
                  {formatDistance(route.totalDistanceMeters)}
                </p>
              </div>
              <div style={{ textAlign: 'center' }}>
                <span style={{ fontSize: '14px', color: '#6b7280' }}>所要時間</span>
                <p style={{ fontSize: '28px', fontWeight: '700', margin: '4px 0 0', color: '#166534' }}>
                  {formatDuration(route.totalDurationSeconds)}
                </p>
              </div>
            </div>
          </div>

          {/* 区間情報 */}
          {geocodedPlaces && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {/* 出発地 */}
              {geocodedPlaces.origin && (
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px',
                  backgroundColor: '#f9fafb',
                  borderRadius: '8px'
                }}>
                  <div style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#22c55e',
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: '600'
                  }}>
                    1
                  </div>
                  <div>
                    <p style={{ margin: 0, fontWeight: '600' }}>{geocodedPlaces.origin.inputAddress}</p>
                    <p style={{ margin: '2px 0 0', fontSize: '14px', color: '#6b7280' }}>
                      {geocodedPlaces.origin.formattedAddress}
                    </p>
                  </div>
                </div>
              )}

              {/* 区間情報 */}
              {route.legs.map((leg, i) => (
                <div key={i} style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  color: '#6b7280',
                  fontSize: '14px'
                }}>
                  <span>↓</span>
                  <span>{formatDistance(leg.distanceMeters)}</span>
                  <span>・</span>
                  <span>{formatDuration(leg.durationSeconds)}</span>
                </div>
              ))}

              {/* 目的地 */}
              {geocodedPlaces.destination && (
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px',
                  backgroundColor: '#f9fafb',
                  borderRadius: '8px'
                }}>
                  <div style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#ef4444',
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: '600'
                  }}>
                    {(geocodedPlaces.waypoints?.length || 0) + 2}
                  </div>
                  <div>
                    <p style={{ margin: 0, fontWeight: '600' }}>{geocodedPlaces.destination.inputAddress}</p>
                    <p style={{ margin: '2px 0 0', fontSize: '14px', color: '#6b7280' }}>
                      {geocodedPlaces.destination.formattedAddress}
                    </p>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* リセットボタン */}
      {searchState === 'done' && (
        <div style={{ textAlign: 'center' }}>
          <button
            onClick={handleReset}
            style={{
              padding: '12px 32px',
              fontSize: '16px',
              fontWeight: '600',
              backgroundColor: '#6b7280',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
            }}
          >
            もう一度検索
          </button>
        </div>
      )}

      {/* 使い方 */}
      <div style={{
        marginTop: '48px',
        padding: '24px',
        backgroundColor: '#f9fafb',
        borderRadius: '8px',
        fontSize: '14px',
        color: '#6b7280'
      }}>
        <h3 style={{ marginBottom: '12px', color: '#374151' }}>使い方</h3>
        <ol style={{ margin: 0, paddingLeft: '20px' }}>
          <li>🎤ボタンを押して話しかけます</li>
          <li>「東京駅から渋谷駅まで行きたい」のように話します</li>
          <li>話し終わったらボタンを押して停止</li>
          <li>AIが出発地と目的地を自動で抽出</li>
          <li>ルート検索結果が表示されます</li>
        </ol>

        <h4 style={{ marginTop: '16px', marginBottom: '8px', color: '#374151' }}>話し方の例</h4>
        <ul style={{ margin: 0, paddingLeft: '20px' }}>
          <li>「新宿駅から東京タワーまでお願いします」</li>
          <li>「品川駅から羽田空港に行きたい」</li>
          <li>「今、渋谷にいるんですけど、原宿まで行けますか」</li>
          <li>「秋葉原から上野公園経由で浅草まで」</li>
        </ul>
      </div>
    </div>
  );
}
