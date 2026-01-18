import { NextRequest, NextResponse } from 'next/server';
import { QwenClient } from '../../../src/qwen-client';
import { getEnv, requireApiKey } from '../../../src/config';

export async function POST(request: NextRequest) {
  try {
    const { message } = await request.json();

    if (!message) {
      return NextResponse.json(
        { error: 'メッセージが必要です' },
        { status: 400 }
      );
    }

    const keyError = requireApiKey('qwen');
    if (keyError) return keyError;

    const env = getEnv();

    console.log('Qwen API call starting...', { region: env.qwenRegion, hasApiKey: !!env.qwenApiKey });

    const qwenClient = new QwenClient(env.qwenApiKey!, env.qwenRegion);
    const response = await qwenClient.chat(message);

    console.log('Qwen API call successful');
    return NextResponse.json({ response });
  } catch (error: any) {
    console.error('Qwen API エラー:', error);
    const errorMessage = error.message || 'Qwen APIの呼び出しに失敗しました';
    return NextResponse.json(
      { error: errorMessage },
      { status: 500 }
    );
  }
}
