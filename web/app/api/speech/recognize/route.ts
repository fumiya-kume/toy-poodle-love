/**
 * 音声認識 API Route
 *
 * 音声ファイルをアップロードして認識結果を返す
 * POST /api/speech/recognize
 */

import { NextRequest, NextResponse } from 'next/server';
import { SpeechRecognitionClient, SpeechRecognitionConfig } from '../../../../src/speech-recognition-client';
import { getEnv } from '../../../../src/config';

interface RecognitionResult {
  text: string;
  transcriptions: string[];
}

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const audioFile = formData.get('audio') as File | null;
    const configJson = formData.get('config') as string | null;

    if (!audioFile) {
      return NextResponse.json({ error: '音声ファイルが必要です' }, { status: 400 });
    }

    const env = getEnv();

    if (!env.qwenApiKey) {
      return NextResponse.json(
        { error: 'QWEN_API_KEY が設定されていません' },
        { status: 500 }
      );
    }

    // 設定をパース
    let config: SpeechRecognitionConfig = {};
    if (configJson) {
      try {
        config = JSON.parse(configJson);
      } catch {
        return NextResponse.json({ error: '設定のJSONが無効です' }, { status: 400 });
      }
    }

    console.log('Speech recognition request:', {
      fileName: audioFile.name,
      size: audioFile.size,
      type: audioFile.type,
      config,
      timestamp: new Date().toISOString(),
    });

    // 音声データを取得
    const audioBuffer = Buffer.from(await audioFile.arrayBuffer());

    // クライアント作成
    const client = new SpeechRecognitionClient(env.qwenApiKey, env.qwenRegion, config);

    // 結果を蓄積
    const transcriptions: string[] = [];

    // コールバック設定
    client.setCallbacks({
      onTranscriptionText: (text: string, isPartial: boolean) => {
        if (!isPartial) {
          transcriptions.push(text);
        }
      },
      onTranscriptionCompleted: (text: string) => {
        console.log('Transcription completed:', text);
      },
      onError: (error) => {
        console.error('Speech recognition error:', error);
      },
    });

    // 接続してセッション開始
    await client.connect();

    // 音声データを送信（チャンクに分割して送信）
    const CHUNK_SIZE = 3200; // 約100ms分（16kHz, 16bit mono = 32000 bytes/sec）
    for (let i = 0; i < audioBuffer.length; i += CHUNK_SIZE) {
      const chunk = audioBuffer.subarray(i, Math.min(i + CHUNK_SIZE, audioBuffer.length));
      client.sendAudio(chunk);
      // 送信間隔を開ける（リアルタイムシミュレーション）
      await new Promise((resolve) => setTimeout(resolve, 50));
    }

    // 送信完了を通知
    await client.finish();

    // 結果を組み立て
    const result: RecognitionResult = {
      text: transcriptions.join(''),
      transcriptions,
    };

    console.log('Speech recognition completed:', {
      textLength: result.text.length,
      transcriptionCount: transcriptions.length,
      timestamp: new Date().toISOString(),
    });

    return NextResponse.json(result);
  } catch (error: unknown) {
    console.error('Speech recognition API error:', error);

    const errorMessage = error instanceof Error ? error.message : '予期しないエラーが発生しました';

    return NextResponse.json({ error: errorMessage }, { status: 500 });
  }
}
