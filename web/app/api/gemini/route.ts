import { NextRequest, NextResponse } from 'next/server';
import { GeminiClient } from '../../../src/gemini-client';
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

    const keyError = requireApiKey('gemini');
    if (keyError) return keyError;

    const env = getEnv();
    const geminiClient = new GeminiClient(env.geminiApiKey!);
    const response = await geminiClient.chat(message);

    return NextResponse.json({ response });
  } catch (error) {
    console.error('Gemini API エラー:', error);
    return NextResponse.json(
      { error: 'Gemini APIの呼び出しに失敗しました' },
      { status: 500 }
    );
  }
}
