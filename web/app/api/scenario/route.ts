import { NextRequest, NextResponse } from 'next/server';
import { ScenarioGenerator } from '../../../src/scenario/generator';
import { ScenarioRequest, ScenarioResponse } from '../../../src/types/api';
import { getEnv, requireApiKey } from '../../../src/config';
import { createScenarioTrace } from '../../../src/langfuse-client';

export async function POST(request: NextRequest) {
  // Langfuseトレースを開始（リクエストボディ解析前に開始）
  const trace = createScenarioTrace('scenario-generation');

  try {
    // JSON解析
    let body: ScenarioRequest;
    try {
      body = await request.json();
    } catch (error) {
      const errorMessage = 'Invalid JSON in request body';
      await trace?.end({ error: errorMessage }).catch(() => {});
      return NextResponse.json<ScenarioResponse>(
        {
          success: false,
          error: errorMessage,
        },
        { status: 400 }
      );
    }

    const { route, models = 'both', includeImagePrompt = false } = body;

    if (!route || !route.routeName || !route.spots) {
      const errorMessage = 'ルート情報が不正です。routeNameとspotsが必要です';
      await trace?.end({ error: errorMessage }).catch(() => {});
      return NextResponse.json<ScenarioResponse>(
        {
          success: false,
          error: errorMessage,
        },
        { status: 400 }
      );
    }

    // トレースにメタデータを更新
    trace?.trace?.update({
      input: {
        routeName: route.routeName,
        spotCount: route.spots.length,
        models,
        includeImagePrompt,
      },
    });

    // 必要なAPIキーが設定されているか確認
    if (models === 'qwen' || models === 'both') {
      const keyError = requireApiKey('qwen');
      if (keyError) {
        const errorMessage = 'QWEN_API_KEY is not configured';
        await trace?.end({ error: errorMessage }).catch(() => {});
        return keyError;
      }
    }

    if (models === 'gemini' || models === 'both') {
      const keyError = requireApiKey('gemini');
      if (keyError) {
        const errorMessage = 'GEMINI_API_KEY is not configured';
        await trace?.end({ error: errorMessage }).catch(() => {});
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
    await trace?.end({
      success: true,
      routeName: result.routeName,
      totalSpots: result.stats.totalSpots,
      successCount: result.stats.successCount,
      processingTimeMs: result.stats.processingTimeMs,
    }).catch(() => {});

    return NextResponse.json<ScenarioResponse>({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('シナリオ生成エラー:', error);
    const errorMessage = error instanceof Error ? error.message : 'シナリオ生成に失敗しました';
    
    // エラーをトレースに記録
    await trace?.end({ error: errorMessage }).catch(() => {});

    return NextResponse.json<ScenarioResponse>(
      {
        success: false,
        error: errorMessage,
      },
      { status: 500 }
    );
  }
}
