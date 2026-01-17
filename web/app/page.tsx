'use client';

import { useState } from 'react';

interface ModelResponse {
  qwen?: string;
  gemini?: string;
}

export default function Home() {
  const [message, setMessage] = useState('');
  const [enabledModels, setEnabledModels] = useState({
    qwen: true,
    gemini: true,
  });
  const [responses, setResponses] = useState<ModelResponse>({});
  const [loading, setLoading] = useState(false);

  const handleModelToggle = (model: 'qwen' | 'gemini') => {
    setEnabledModels(prev => ({
      ...prev,
      [model]: !prev[model],
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!message.trim()) {
      alert('メッセージを入力してください');
      return;
    }

    if (!enabledModels.qwen && !enabledModels.gemini) {
      alert('少なくとも1つのモデルを選択してください');
      return;
    }

    setLoading(true);
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
      setLoading(false);
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
        AI テキスト生成
      </h1>

      <form onSubmit={handleSubmit}>
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
          disabled={loading}
          style={{
            width: '100%',
            padding: '12px 24px',
            fontSize: '16px',
            fontWeight: '600',
            backgroundColor: loading ? '#ccc' : '#0070f3',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: loading ? 'not-allowed' : 'pointer',
            transition: 'background-color 0.2s'
          }}
        >
          {loading ? '生成中...' : '送信'}
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
  );
}
