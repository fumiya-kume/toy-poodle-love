import { NextRequest, NextResponse } from 'next/server';
import { QwenClient } from '../../../src/qwen-client';

export async function POST(request: NextRequest) {
  try {
    const { message } = await request.json();

    if (!message) {
      return NextResponse.json(
        { error: 'メッセージが必要です' },
        { status: 400 }
      );
    }

    const apiKey = process.env.QWEN_API_KEY;
    const region = (process.env.QWEN_REGION as 'china' | 'international') || 'international';

    if (!apiKey) {
      console.error('QWEN_API_KEY not configured');
      return NextResponse.json(
        { error: 'QWEN_API_KEYが設定されていません。環境変数を確認してください。' },
        { status: 500 }
      );
    }

    console.log('Qwen API call starting...', { region, hasApiKey: !!apiKey });

    const qwenClient = new QwenClient(apiKey, region);
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
