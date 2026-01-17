import { NextRequest, NextResponse } from 'next/server';
import { ScenarioIntegrator } from '../../../../src/scenario/integrator';
import { ScenarioIntegrationRequest, ScenarioIntegrationResponse } from '../../../../src/types/api';

export async function POST(request: NextRequest) {
  try {
    const body: ScenarioIntegrationRequest = await request.json();
    const { integration } = body;

    if (!integration || !integration.routeName || !integration.spots || !integration.sourceModel) {
      return NextResponse.json<ScenarioIntegrationResponse>(
        {
          success: false,
          error: '統合情報が不正です。routeName、spots、sourceModelが必要です',
        },
        { status: 400 }
      );
    }

    // 環境変数からAPIキーを取得
    const qwenApiKey = process.env.QWEN_API_KEY;
    const geminiApiKey = process.env.GEMINI_API_KEY;
    const qwenRegion = (process.env.QWEN_REGION as 'china' | 'international') || 'international';

    // 統合に使用するLLMを決定
    const integrationLLM = integration.integrationLLM ||
      (integration.sourceModel === 'qwen' ? 'gemini' : 'qwen');

    // 必要なAPIキーが設定されているか確認
    if (integrationLLM === 'qwen' && !qwenApiKey) {
      return NextResponse.json<ScenarioIntegrationResponse>(
        {
          success: false,
          error: 'QWEN_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    if (integrationLLM === 'gemini' && !geminiApiKey) {
      return NextResponse.json<ScenarioIntegrationResponse>(
        {
          success: false,
          error: 'GEMINI_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    // ScenarioIntegratorを初期化
    const integrator = new ScenarioIntegrator(
      qwenApiKey,
      geminiApiKey,
      qwenRegion
    );

    // シナリオ統合
    const result = await integrator.integrate(integration);

    return NextResponse.json<ScenarioIntegrationResponse>({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error('シナリオ統合エラー:', error);
    return NextResponse.json<ScenarioIntegrationResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : 'シナリオ統合に失敗しました',
      },
      { status: 500 }
    );
  }
}
