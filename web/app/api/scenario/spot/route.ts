import { NextRequest, NextResponse } from 'next/server';
import { ScenarioGenerator } from '../../../../src/scenario/generator';
import { SpotScenarioRequest, SpotScenarioResponse } from '../../../../src/types/api';

export async function POST(request: NextRequest) {
  try {
    const body: SpotScenarioRequest = await request.json();
    const { routeName, spotName, description, point, models = 'both' } = body;

    if (!routeName || !spotName) {
      return NextResponse.json<SpotScenarioResponse>(
        {
          success: false,
          error: 'routeNameとspotNameが必要です',
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
        return NextResponse.json<SpotScenarioResponse>(
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
        return NextResponse.json<SpotScenarioResponse>(
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
    const result = await generator.generateSingleSpot(
      routeName,
      spotName,
      description,
      point,
      models
    );

    return NextResponse.json<SpotScenarioResponse>({
      success: true,
      scenario: result,
    });
  } catch (error) {
    console.error('地点シナリオ生成エラー:', error);
    return NextResponse.json<SpotScenarioResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : '地点シナリオ生成に失敗しました',
      },
      { status: 500 }
    );
  }
}
