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
      return NextResponse.json(
        { error: 'QWEN_API_KEYが設定されていません' },
        { status: 500 }
      );
    }

    const qwenClient = new QwenClient(apiKey, region);
    const response = await qwenClient.chat(message);

    return NextResponse.json({ response });
  } catch (error) {
    console.error('Qwen API エラー:', error);
    return NextResponse.json(
      { error: 'Qwen APIの呼び出しに失敗しました' },
      { status: 500 }
    );
  }
}
