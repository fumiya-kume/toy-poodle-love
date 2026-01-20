import { NextRequest, NextResponse } from 'next/server';
import { QwenTTSClient, QwenTTSModel, AudioFormat } from '../../../src/qwen-tts-client';
import { requireApiKey } from '../../../src/config/api-helpers';
import { getEnv } from '../../../src/config/env';

// Valid model and format values for validation
const VALID_MODELS: QwenTTSModel[] = [
  'qwen3-tts-flash-realtime',
  'qwen3-tts-flash-realtime-2025-11-27',
  'qwen3-tts-vc-realtime',
  'qwen3-tts-vc-realtime-2026-01-15',
  'qwen3-tts-vd-realtime',
  'qwen3-tts-vd-realtime-2025-12-16',
];

const VALID_FORMATS: AudioFormat[] = ['pcm', 'wav', 'mp3', 'opus'];

const MIN_SAMPLE_RATE = 8000;
const MAX_SAMPLE_RATE = 48000;

function createWavHeader(dataLength: number, sampleRate: number, channels: number = 1, bitsPerSample: number = 16): Buffer {
  const header = Buffer.alloc(44);
  const byteRate = sampleRate * channels * bitsPerSample / 8;
  const blockAlign = channels * bitsPerSample / 8;

  header.write('RIFF', 0);
  header.writeUInt32LE(36 + dataLength, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataLength, 40);

  return header;
}

export async function POST(request: NextRequest) {
  try {
    // Use standard API key validation helper
    const keyError = requireApiKey('qwen');
    if (keyError) return keyError;

    const { text, model, voice, format, sampleRate } = await request.json();

    // Validate required parameter
    if (!text) {
      return NextResponse.json(
        { success: false, error: 'テキストが必要です' },
        { status: 400 }
      );
    }

    // Validate model parameter
    if (model && !VALID_MODELS.includes(model)) {
      return NextResponse.json(
        { success: false, error: `Invalid model. Must be one of: ${VALID_MODELS.join(', ')}` },
        { status: 400 }
      );
    }

    // Validate format parameter
    if (format && !VALID_FORMATS.includes(format)) {
      return NextResponse.json(
        { success: false, error: `Invalid format. Must be one of: ${VALID_FORMATS.join(', ')}` },
        { status: 400 }
      );
    }

    // Validate sampleRate parameter
    if (sampleRate !== undefined) {
      const rate = Number(sampleRate);
      if (isNaN(rate) || rate < MIN_SAMPLE_RATE || rate > MAX_SAMPLE_RATE) {
        return NextResponse.json(
          { success: false, error: `Sample rate must be between ${MIN_SAMPLE_RATE} and ${MAX_SAMPLE_RATE}` },
          { status: 400 }
        );
      }
    }

    const env = getEnv();
    const actualSampleRate = sampleRate || 24000;

    console.log('TTS API call starting...', {
      textLength: text.length,
      model: model || 'qwen3-tts-flash-realtime',
      voice: voice || 'Cherry',
      format: format || 'pcm',
      sampleRate: actualSampleRate,
      region: env.qwenRegion,
    });

    const ttsClient = new QwenTTSClient(env.qwenApiKey!, env.qwenRegion);
    const audioBuffer = await ttsClient.synthesize(text, {
      model: model as QwenTTSModel,
      voice: voice || 'Cherry',
      format: (format as AudioFormat) || 'pcm',
      sampleRate: actualSampleRate,
    });

    console.log('TTS API call successful, audio size:', audioBuffer.length);

    // PCM形式の場合、WAVヘッダーを追加してブラウザで再生可能にする
    const actualFormat = format || 'pcm';
    if (actualFormat === 'pcm') {
      const wavHeader = createWavHeader(audioBuffer.length, actualSampleRate);
      const wavBuffer = Buffer.concat([wavHeader, audioBuffer]);

      return new NextResponse(new Uint8Array(wavBuffer), {
        headers: {
          'Content-Type': 'audio/wav',
          'Content-Length': wavBuffer.length.toString(),
        },
      });
    }

    const mimeType = actualFormat === 'wav' ? 'audio/wav'
      : actualFormat === 'opus' ? 'audio/opus'
      : 'audio/mpeg';

    return new NextResponse(new Uint8Array(audioBuffer), {
      headers: {
        'Content-Type': mimeType,
        'Content-Length': audioBuffer.length.toString(),
      },
    });
  } catch (error: unknown) {
    console.error('TTS API エラー:', error);
    const errorMessage = error instanceof Error ? error.message : 'TTS APIの呼び出しに失敗しました';
    return NextResponse.json(
      { success: false, error: errorMessage },
      { status: 500 }
    );
  }
}
