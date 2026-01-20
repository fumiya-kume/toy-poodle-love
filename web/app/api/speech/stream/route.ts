/**
 * リアルタイム音声認識 SSE API Route
 *
 * Server-Sent Events を使用してリアルタイムで認識結果を返す
 * POST /api/speech/stream
 */

import { NextRequest } from 'next/server';
import { SpeechRecognitionClient, SpeechRecognitionConfig } from '@/src/speech-recognition-client';
import { getEnv } from '@/src/config';

interface StreamRequest {
  audio: string; // Base64エンコードされた音声データ
  config?: SpeechRecognitionConfig;
}

// SSEイベントタイプ
type SSEEventType = 'started' | 'partial' | 'final' | 'finished' | 'error';

interface SSEEvent {
  type: SSEEventType;
  data: unknown;
}

function formatSSE(event: SSEEvent): string {
  return `event: ${event.type}\ndata: ${JSON.stringify(event.data)}\n\n`;
}

export async function POST(request: NextRequest) {
  const env = getEnv();

  if (!env.qwenApiKey) {
    return new Response(JSON.stringify({ error: 'QWEN_API_KEY が設定されていません' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  let body: StreamRequest;
  try {
    body = await request.json();
  } catch {
    return new Response(JSON.stringify({ error: 'リクエストボディが無効です' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (!body.audio) {
    return new Response(JSON.stringify({ error: '音声データが必要です' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const config: SpeechRecognitionConfig = body.config || {};

  console.log('Stream recognition request:', {
    audioLength: body.audio.length,
    config,
    timestamp: new Date().toISOString(),
  });

  // ReadableStreamを使ってSSEを実装
  const abortSignal = request.signal;

  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      let client: SpeechRecognitionClient | null = null;
      let isAborted = false;

      const sendEvent = (event: SSEEvent) => {
        if (!isAborted) {
          try {
            controller.enqueue(encoder.encode(formatSSE(event)));
          } catch {
            // Controller already closed
          }
        }
      };

      // abort時のクリーンアップ
      const handleAbort = () => {
        isAborted = true;
        if (client) {
          try {
            client.disconnect();
          } catch {
            // Ignore disconnect errors
          }
        }
        sendEvent({ type: 'error', data: { message: 'リクエストが中断されました' } });
        try {
          controller.close();
        } catch {
          // Controller already closed
        }
      };

      abortSignal.addEventListener('abort', handleAbort);

      try {
        // 音声データをデコード
        const audioBuffer = Buffer.from(body.audio, 'base64');

        // クライアント作成
        client = new SpeechRecognitionClient(env.qwenApiKey!, env.qwenRegion, config);

        // コールバック設定
        client.setCallbacks({
          onSessionCreated: (sessionId: string) => {
            sendEvent({
              type: 'started',
              data: { sessionId },
            });
          },
          onTranscriptionText: (text: string, isPartial: boolean) => {
            sendEvent({
              type: isPartial ? 'partial' : 'final',
              data: { text },
            });
          },
          onTranscriptionCompleted: (text: string) => {
            sendEvent({
              type: 'finished',
              data: { text },
            });
          },
          onError: (error) => {
            const errorData = 'code' in error
              ? { code: error.code, message: error.message }
              : { message: (error as Error).message };
            sendEvent({ type: 'error', data: errorData });
          },
        });

        // abort済みなら接続しない
        if (isAborted) return;

        // 接続
        await client.connect();

        // 音声データを送信（チャンクに分割）
        const CHUNK_SIZE = 3200;
        for (let i = 0; i < audioBuffer.length; i += CHUNK_SIZE) {
          if (isAborted) break;
          const chunk = audioBuffer.subarray(i, Math.min(i + CHUNK_SIZE, audioBuffer.length));
          client.sendAudio(chunk);
          await new Promise((resolve) => setTimeout(resolve, 50));
        }

        // abort済みでなければ完了処理
        if (!isAborted) {
          await client.finish();
        }
      } catch (error) {
        console.error('Stream recognition error:', error);
        sendEvent({
          type: 'error',
          data: {
            message: error instanceof Error ? error.message : '予期しないエラーが発生しました',
          },
        });
      } finally {
        abortSignal.removeEventListener('abort', handleAbort);
        if (!isAborted) {
          try {
            controller.close();
          } catch {
            // Controller already closed
          }
        }
      }
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
