'use client';

import { useState, useRef } from 'react';

type QwenTTSModel =
  | 'qwen3-tts-flash-realtime'
  | 'qwen3-tts-flash-realtime-2025-11-27'
  | 'qwen3-tts-vc-realtime'
  | 'qwen3-tts-vc-realtime-2026-01-15'
  | 'qwen3-tts-vd-realtime'
  | 'qwen3-tts-vd-realtime-2025-12-16';

export default function TTSPage() {
  const [text, setText] = useState('');
  const [model, setModel] = useState<QwenTTSModel>('qwen3-tts-flash-realtime');
  const [voice, setVoice] = useState('Cherry');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const audioRef = useRef<HTMLAudioElement>(null);

  const handleSynthesize = async () => {
    if (!text.trim()) {
      setError('テキストを入力してください');
      return;
    }

    setIsLoading(true);
    setError(null);
    setAudioUrl(null);

    try {
      const response = await fetch('/api/tts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          model,
          voice,
          format: 'pcm',
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'TTS APIの呼び出しに失敗しました');
      }

      const audioBlob = await response.blob();
      const url = URL.createObjectURL(audioBlob);
      setAudioUrl(url);

      if (audioRef.current) {
        audioRef.current.load();
        audioRef.current.play();
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
      <h1 style={{ marginBottom: '20px' }}>Qwen TTS</h1>

      <div style={{ marginBottom: '15px' }}>
        <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
          テキスト
        </label>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="音声に変換するテキストを入力..."
          rows={4}
          style={{
            width: '100%',
            padding: '10px',
            border: '1px solid #ccc',
            borderRadius: '4px',
            fontSize: '14px',
          }}
        />
      </div>

      <div style={{ marginBottom: '15px' }}>
        <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
          モデル
        </label>
        <select
          value={model}
          onChange={(e) => setModel(e.target.value as QwenTTSModel)}
          style={{
            width: '100%',
            padding: '10px',
            border: '1px solid #ccc',
            borderRadius: '4px',
            fontSize: '14px',
          }}
        >
          <option value="qwen3-tts-flash-realtime">qwen3-tts-flash-realtime (stable)</option>
          <option value="qwen3-tts-flash-realtime-2025-11-27">qwen3-tts-flash-realtime-2025-11-27</option>
          <option value="qwen3-tts-vc-realtime">qwen3-tts-vc-realtime</option>
          <option value="qwen3-tts-vc-realtime-2026-01-15">qwen3-tts-vc-realtime-2026-01-15</option>
          <option value="qwen3-tts-vd-realtime">qwen3-tts-vd-realtime</option>
          <option value="qwen3-tts-vd-realtime-2025-12-16">qwen3-tts-vd-realtime-2025-12-16</option>
        </select>
      </div>

      <div style={{ marginBottom: '15px' }}>
        <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
          Voice
        </label>
        <input
          type="text"
          value={voice}
          onChange={(e) => setVoice(e.target.value)}
          placeholder="longanyang"
          style={{
            width: '100%',
            padding: '10px',
            border: '1px solid #ccc',
            borderRadius: '4px',
            fontSize: '14px',
          }}
        />
      </div>

      <button
        onClick={handleSynthesize}
        disabled={isLoading}
        style={{
          width: '100%',
          padding: '12px',
          backgroundColor: isLoading ? '#ccc' : '#0070f3',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          fontSize: '16px',
          cursor: isLoading ? 'not-allowed' : 'pointer',
        }}
      >
        {isLoading ? '生成中...' : '音声を生成'}
      </button>

      {error && (
        <div
          style={{
            marginTop: '15px',
            padding: '10px',
            backgroundColor: '#fee',
            border: '1px solid #f00',
            borderRadius: '4px',
            color: '#c00',
          }}
        >
          {error}
        </div>
      )}

      {audioUrl && (
        <div style={{ marginTop: '20px' }}>
          <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
            生成された音声
          </label>
          <audio
            ref={audioRef}
            controls
            style={{ width: '100%' }}
          >
            <source src={audioUrl} type="audio/wav" />
          </audio>
        </div>
      )}
    </div>
  );
}
