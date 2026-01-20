'use client';

import { useState, useRef, useCallback } from 'react';

type RecognitionMode = 'batch' | 'stream';

interface RecognitionResult {
  text: string;
  isPartial?: boolean;
}

export default function SpeechPage() {
  const [isRecording, setIsRecording] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [mode, setMode] = useState<RecognitionMode>('batch');
  const [results, setResults] = useState<RecognitionResult[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [audioLevel, setAudioLevel] = useState(0);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);

  const updateAudioLevel = useCallback(() => {
    if (analyserRef.current) {
      const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount);
      analyserRef.current.getByteFrequencyData(dataArray);
      const average = dataArray.reduce((a, b) => a + b, 0) / dataArray.length;
      setAudioLevel(average / 255);
    }
    animationFrameRef.current = requestAnimationFrame(updateAudioLevel);
  }, []);

  const startRecording = async () => {
    try {
      setError(null);
      setResults([]);

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

      // PCM16データを収集するためのScriptProcessorNode
      const scriptProcessor = audioContext.createScriptProcessor(4096, 1, 1);
      const pcmChunks: Int16Array[] = [];

      scriptProcessor.onaudioprocess = (event) => {
        const inputData = event.inputBuffer.getChannelData(0);
        // Float32 to Int16 conversion
        const pcmData = new Int16Array(inputData.length);
        for (let i = 0; i < inputData.length; i++) {
          const s = Math.max(-1, Math.min(1, inputData[i]));
          pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
        }
        pcmChunks.push(pcmData);
      };

      source.connect(scriptProcessor);
      scriptProcessor.connect(audioContext.destination);

      // MediaRecorderは使わず、生のPCMデータを収集
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

          // Int16ArrayをBufferに変換
          const audioBuffer = new Uint8Array(combinedPcm.buffer);

          if (mode === 'batch') {
            await processBatch(audioBuffer);
          } else {
            await processStream(audioBuffer);
          }

          await audioContext.close();
        },
      } as unknown as MediaRecorder;

      setIsRecording(true);
    } catch (err) {
      console.error('Recording error:', err);
      setError(
        err instanceof Error ? err.message : 'マイクへのアクセスに失敗しました'
      );
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
    }
  };

  const processBatch = async (audioData: Uint8Array) => {
    setIsProcessing(true);
    try {
      const formData = new FormData();
      // PCM16データをBlobとして送信
      const audioBlob = new Blob([audioData.buffer as ArrayBuffer], { type: 'audio/pcm' });
      formData.append('audio', audioBlob, 'recording.pcm');
      formData.append(
        'config',
        JSON.stringify({
          model: 'qwen3-asr-flash-realtime',
          sampleRate: 16000,
        })
      );

      const response = await fetch('/api/speech/recognize', {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || '認識に失敗しました');
      }

      setResults([{ text: data.text, isPartial: false }]);
    } catch (err) {
      console.error('Batch processing error:', err);
      setError(err instanceof Error ? err.message : '処理に失敗しました');
    } finally {
      setIsProcessing(false);
    }
  };

  const processStream = async (audioData: Uint8Array) => {
    setIsProcessing(true);
    try {
      // Uint8Arrayをbase64に変換
      const base64 = btoa(
        Array.from(audioData)
          .map((byte) => String.fromCharCode(byte))
          .join('')
      );

      const response = await fetch('/api/speech/stream', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          audio: base64,
          config: {
            model: 'qwen3-asr-flash-realtime',
            sampleRate: 16000,
          },
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || '認識に失敗しました');
      }

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();

      if (!reader) {
        throw new Error('ストリームの読み取りに失敗しました');
      }

      let buffer = '';
      let currentEvent = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });

        // SSEイベントをパース
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          // event: 行を検出
          if (line.startsWith('event: ')) {
            currentEvent = line.slice(7);
            continue;
          }

          // 空行でイベント区切りをリセット
          if (line === '') {
            currentEvent = '';
            continue;
          }

          // data: 行を処理
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));

              if (currentEvent === 'partial') {
                setResults((prev) => {
                  const newResults = [...prev];
                  // 最後の部分結果を更新
                  if (newResults.length > 0 && newResults[newResults.length - 1].isPartial) {
                    newResults[newResults.length - 1] = {
                      text: data.text,
                      isPartial: true,
                    };
                  } else {
                    newResults.push({ text: data.text, isPartial: true });
                  }
                  return newResults;
                });
              } else if (currentEvent === 'final') {
                setResults((prev) => {
                  const newResults = prev.filter((r) => !r.isPartial);
                  newResults.push({ text: data.text, isPartial: false });
                  return newResults;
                });
              } else if (currentEvent === 'error') {
                throw new Error(data.message || 'ストリーム処理エラー');
              }
            } catch (e) {
              // errorイベントのJSONパースエラーは再スロー
              if (currentEvent === 'error' && e instanceof Error) {
                throw e;
              }
              // その他のJSONパースエラーは無視
            }
          }
        }
      }
    } catch (err) {
      console.error('Stream processing error:', err);
      setError(err instanceof Error ? err.message : '処理に失敗しました');
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
      <h1 style={{ marginBottom: '20px' }}>音声認識テスト (Qwen3-ASR)</h1>

      {/* モード選択 */}
      <div style={{ marginBottom: '20px' }}>
        <label style={{ marginRight: '20px' }}>
          <input
            type="radio"
            name="mode"
            value="batch"
            checked={mode === 'batch'}
            onChange={() => setMode('batch')}
            disabled={isRecording || isProcessing}
          />
          バッチ処理
        </label>
        <label>
          <input
            type="radio"
            name="mode"
            value="stream"
            checked={mode === 'stream'}
            onChange={() => setMode('stream')}
            disabled={isRecording || isProcessing}
          />
          ストリーミング (SSE)
        </label>
      </div>

      {/* 録音ボタン */}
      <div style={{ marginBottom: '20px' }}>
        <button
          onClick={isRecording ? stopRecording : startRecording}
          disabled={isProcessing}
          style={{
            padding: '15px 30px',
            fontSize: '18px',
            backgroundColor: isRecording ? '#dc3545' : '#007bff',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: isProcessing ? 'not-allowed' : 'pointer',
            opacity: isProcessing ? 0.6 : 1,
          }}
        >
          {isProcessing
            ? '処理中...'
            : isRecording
              ? '録音停止'
              : '録音開始'}
        </button>
      </div>

      {/* オーディオレベル */}
      {isRecording && (
        <div style={{ marginBottom: '20px' }}>
          <div
            style={{
              height: '10px',
              backgroundColor: '#e0e0e0',
              borderRadius: '5px',
              overflow: 'hidden',
            }}
          >
            <div
              style={{
                height: '100%',
                width: `${audioLevel * 100}%`,
                backgroundColor: audioLevel > 0.5 ? '#28a745' : '#ffc107',
                transition: 'width 0.1s',
              }}
            />
          </div>
          <p style={{ fontSize: '14px', color: '#666', marginTop: '5px' }}>
            話してください...
          </p>
        </div>
      )}

      {/* エラー表示 */}
      {error && (
        <div
          style={{
            padding: '10px',
            backgroundColor: '#f8d7da',
            color: '#721c24',
            borderRadius: '4px',
            marginBottom: '20px',
          }}
        >
          {error}
        </div>
      )}

      {/* 認識結果 */}
      <div>
        <h2 style={{ marginBottom: '10px' }}>認識結果</h2>
        <div
          style={{
            minHeight: '100px',
            padding: '15px',
            backgroundColor: '#f5f5f5',
            borderRadius: '8px',
            whiteSpace: 'pre-wrap',
          }}
        >
          {results.length === 0 ? (
            <span style={{ color: '#999' }}>
              録音して認識結果をここに表示します
            </span>
          ) : (
            results.map((result, index) => (
              <span
                key={index}
                style={{
                  color: result.isPartial ? '#666' : '#000',
                  fontStyle: result.isPartial ? 'italic' : 'normal',
                }}
              >
                {result.text}
              </span>
            ))
          )}
        </div>
      </div>

      {/* 使い方 */}
      <div style={{ marginTop: '30px', fontSize: '14px', color: '#666' }}>
        <h3>使い方</h3>
        <ol>
          <li>処理モードを選択（バッチ or ストリーミング）</li>
          <li>「録音開始」ボタンをクリック</li>
          <li>マイクへのアクセスを許可</li>
          <li>話し終わったら「録音停止」をクリック</li>
          <li>認識結果が表示されます</li>
        </ol>
        <p style={{ marginTop: '10px' }}>
          <strong>モデル:</strong> qwen3-asr-flash-realtime (国際版)
        </p>
        <p>
          <strong>注意:</strong> QWEN_API_KEYが設定されている必要があります。
        </p>
      </div>
    </div>
  );
}
