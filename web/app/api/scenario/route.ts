import { NextRequest, NextResponse } from 'next/server';
import { ScenarioGenerator } from '../../../src/scenario/generator';
import { ScenarioRequest, ScenarioResponse } from '../../../src/types/api';
import { getEnv, requireApiKey } from '../../../src/config';
import { createScenarioTrace } from '../../../src/langfuse-client';

export async function POST(request: NextRequest) {
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

  // Langfuseトレースを開始
  const trace = createScenarioTrace('scenario-generation', {
    routeName: route.routeName,
    spotCount: route.spots.length,
    models,
    includeImagePrompt,
  });

  try {
    // 必要なAPIキーが設定されているか確認
    if (models === 'qwen' || models === 'both') {
      const keyError = requireApiKey('qwen');
      if (keyError) {
        trace?.end({ error: keyError });
        return keyError;
      }
    }

    if (models === 'gemini' || models === 'both') {
      const keyError = requireApiKey('gemini');
      if (keyError) {
        trace?.end({ error: keyError });
        return keyError;
      }
    }

    const env = getEnv();

    // ScenarioGeneratorを初期化
    const generator = new ScenarioGenerator(
      env.qwenApiKey,
      env.geminiApiKey,
      env.qwenRegion
    );

    // シナリオ生成
    const result = await generator.generateRoute(route, models, includeImagePrompt);

    // トレースを終了
    trace?.end({
      success: true,
      routeName: result.routeName,
      totalSpots: result.stats.totalSpots,
      successCount: result.stats.successCount,
      processingTimeMs: result.stats.processingTimeMs,
    });

    return NextResponse.json<ScenarioResponse>({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('シナリオ生成エラー:', error);
    const errorMessage = error instanceof Error ? error.message : 'シナリオ生成に失敗しました';
    
    // エラーをトレースに記録
    trace?.end({ error: errorMessage });

    return NextResponse.json<ScenarioResponse>(
      {
        success: false,
        error: errorMessage,
      },
      { status: 500 }
    );
  }
}
