/**
 * リアルタイム音声認識 SSE API Route
 *
 * Server-Sent Events を使用してリアルタイムで認識結果を返す
 * POST /api/speech/stream
 */

import { NextRequest } from 'next/server';
import { SpeechRecognitionClient, SpeechRecognitionConfig } from '../../../../src/speech-recognition-client';
import { getEnv } from '../../../../src/config';

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
  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();

      const sendEvent = (event: SSEEvent) => {
        controller.enqueue(encoder.encode(formatSSE(event)));
      };

      try {
        // 音声データをデコード
        const audioBuffer = Buffer.from(body.audio, 'base64');

        // クライアント作成
        const client = new SpeechRecognitionClient(env.qwenApiKey!, env.qwenRegion, config);

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

        // 接続
        await client.connect();

        // 音声データを送信（チャンクに分割）
        const CHUNK_SIZE = 3200;
        for (let i = 0; i < audioBuffer.length; i += CHUNK_SIZE) {
          const chunk = audioBuffer.subarray(i, Math.min(i + CHUNK_SIZE, audioBuffer.length));
          client.sendAudio(chunk);
          await new Promise((resolve) => setTimeout(resolve, 50));
        }

        // 完了
        await client.finish();
      } catch (error) {
        console.error('Stream recognition error:', error);
        sendEvent({
          type: 'error',
          data: {
            message: error instanceof Error ? error.message : '予期しないエラーが発生しました',
          },
        });
      } finally {
        controller.close();
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
