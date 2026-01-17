import { NextRequest, NextResponse } from 'next/server';
import { GeminiClient } from '../../../src/gemini-client';

export async function POST(request: NextRequest) {
  try {
    const { message } = await request.json();

    if (!message) {
      return NextResponse.json(
        { error: 'メッセージが必要です' },
        { status: 400 }
      );
    }

    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return NextResponse.json(
        { error: 'GEMINI_API_KEYが設定されていません' },
        { status: 500 }
      );
    }

    const geminiClient = new GeminiClient(apiKey);
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
