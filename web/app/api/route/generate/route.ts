import { NextRequest, NextResponse } from 'next/server';
import { RouteGenerator } from '../../../../src/route/generator';
import { RouteGenerationRequest, RouteGenerationResponse } from '../../../../src/types/api';
import { getEnv, requireApiKey } from '../../../../src/config';

export async function POST(request: NextRequest) {
  try {
    const body: RouteGenerationRequest = await request.json();
    const { input } = body;

    // バリデーション
    if (!input || !input.startPoint || !input.purpose) {
      return NextResponse.json<RouteGenerationResponse>(
        {
          success: false,
          error: '入力情報が不正です。startPointとpurposeが必要です',
        },
        { status: 400 }
      );
    }

    if (!input.spotCount || input.spotCount < 3 || input.spotCount > 8) {
      return NextResponse.json<RouteGenerationResponse>(
        {
          success: false,
          error: '地点数は3〜8の範囲で指定してください',
        },
        { status: 400 }
      );
    }

    if (!input.model || (input.model !== 'qwen' && input.model !== 'gemini')) {
      return NextResponse.json<RouteGenerationResponse>(
        {
          success: false,
          error: 'モデルはqwenまたはgeminiを指定してください',
        },
        { status: 400 }
      );
    }

    // 必要なAPIキーが設定されているか確認
    if (input.model === 'qwen') {
      const keyError = requireApiKey('qwen');
      if (keyError) return keyError;
    }

    if (input.model === 'gemini') {
      const keyError = requireApiKey('gemini');
      if (keyError) return keyError;
    }

    const env = getEnv();

    // RouteGeneratorを初期化
    const generator = new RouteGenerator(
      env.qwenApiKey,
      env.geminiApiKey,
      env.qwenRegion
    );

    // ルート生成
    const result = await generator.generate(input);

    return NextResponse.json<RouteGenerationResponse>({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('ルート生成エラー:', error);
    return NextResponse.json<RouteGenerationResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : 'ルート生成に失敗しました',
      },
      { status: 500 }
    );
  }
}
