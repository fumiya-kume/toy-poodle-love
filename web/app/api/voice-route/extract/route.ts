/**
 * 音声認識テキストから出発地・目的地を抽出するAPIエンドポイント
 *
 * POST /api/voice-route/extract
 *
 * Request Body:
 *   - text: string (音声認識で得られたテキスト)
 *   - model?: 'qwen' | 'gemini' (使用するLLMモデル、デフォルト: gemini)
 *
 * Response:
 *   - success: boolean
 *   - location?: ExtractedLocation
 *   - error?: string
 */

import { NextResponse } from 'next/server';
import { LocationExtractor } from '../../../../src/location-extractor';
import type { ExtractLocationRequest, ExtractLocationResponse } from '../../../../src/types/voice-route';

export async function POST(request: Request) {
  try {
    const body: ExtractLocationRequest = await request.json();

    // バリデーション
    if (!body.text || typeof body.text !== 'string') {
      return NextResponse.json<ExtractLocationResponse>({
        success: false,
        error: 'テキストが必要です',
      }, { status: 400 });
    }

    if (body.text.trim().length === 0) {
      return NextResponse.json<ExtractLocationResponse>({
        success: false,
        error: 'テキストが空です',
      }, { status: 400 });
    }

    const model = body.model || 'gemini';
    if (model !== 'qwen' && model !== 'gemini') {
      return NextResponse.json<ExtractLocationResponse>({
        success: false,
        error: 'モデルは "qwen" または "gemini" を指定してください',
      }, { status: 400 });
    }

    console.log('Extracting location from text:', {
      textLength: body.text.length,
      textPreview: body.text.substring(0, 100),
      model,
    });

    // 地点抽出を実行
    const extractor = new LocationExtractor();
    const location = await extractor.extract(body.text, model);

    console.log('Location extracted:', location);

    return NextResponse.json<ExtractLocationResponse>({
      success: true,
      location,
    });

  } catch (error) {
    console.error('Location extraction error:', error);

    const errorMessage = error instanceof Error ? error.message : '地点の抽出に失敗しました';

    return NextResponse.json<ExtractLocationResponse>({
      success: false,
      error: errorMessage,
    }, { status: 500 });
  }
}
