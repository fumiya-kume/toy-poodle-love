'use client';

import { useEffect } from 'react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Application error:', error);
  }, [error]);

  return (
    <div style={{
      padding: '40px',
      maxWidth: '600px',
      margin: '0 auto',
      fontFamily: 'system-ui, -apple-system, sans-serif',
    }}>
      <h2 style={{ color: '#dc2626', marginBottom: '16px' }}>
        エラーが発生しました
      </h2>
      <p style={{ marginBottom: '16px', color: '#4b5563' }}>
        {error.message || '不明なエラーが発生しました'}
      </p>
      {error.digest && (
        <p style={{ marginBottom: '16px', fontSize: '12px', color: '#9ca3af' }}>
          エラーID: {error.digest}
        </p>
      )}
      <button
        onClick={reset}
        style={{
          padding: '12px 24px',
          fontSize: '16px',
          backgroundColor: '#0070f3',
          color: 'white',
          border: 'none',
          borderRadius: '8px',
          cursor: 'pointer',
        }}
      >
        再試行
      </button>
    </div>
  );
}
