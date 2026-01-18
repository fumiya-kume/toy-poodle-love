import { NextRequest, NextResponse } from 'next/server';
import { ScenarioGenerator } from '../../../src/scenario/generator';
import { ScenarioRequest, ScenarioResponse } from '../../../src/types/api';

export async function POST(request: NextRequest) {
  try {
    const body: ScenarioRequest = await request.json();
    const { route, models = 'both', includeImagePrompt = false } = body;

    if (!route || !route.routeName || !route.spots) {
      return NextResponse.json<ScenarioResponse>(
        {
          success: false,
          error: 'ルート情報が不正です。routeNameとspotsが必要です',
        },
        { status: 400 }
      );
    }

    // 環境変数からAPIキーを取得
    const qwenApiKey = process.env.QWEN_API_KEY;
    const geminiApiKey = process.env.GEMINI_API_KEY;
    const qwenRegion = (process.env.QWEN_REGION as 'china' | 'international') || 'international';

    // 必要なAPIキーが設定されているか確認
    if (models === 'qwen' || models === 'both') {
      if (!qwenApiKey) {
        return NextResponse.json<ScenarioResponse>(
          {
            success: false,
            error: 'QWEN_API_KEYが設定されていません',
          },
          { status: 500 }
        );
      }
    }

    if (models === 'gemini' || models === 'both') {
      if (!geminiApiKey) {
        return NextResponse.json<ScenarioResponse>(
          {
            success: false,
            error: 'GEMINI_API_KEYが設定されていません',
          },
          { status: 500 }
        );
      }
    }

    // ScenarioGeneratorを初期化
    const generator = new ScenarioGenerator(
      qwenApiKey,
      geminiApiKey,
      qwenRegion
    );

    // シナリオ生成
    const result = await generator.generateRoute(route, models, includeImagePrompt);

    return NextResponse.json<ScenarioResponse>({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('シナリオ生成エラー:', error);
    return NextResponse.json<ScenarioResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : 'シナリオ生成に失敗しました',
      },
      { status: 500 }
    );
  }
}
