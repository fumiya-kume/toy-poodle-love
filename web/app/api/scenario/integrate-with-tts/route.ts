import { NextRequest, NextResponse } from 'next/server';
import { ScenarioIntegrator } from '../../../../src/scenario/integrator';
import { ScenarioIntegrationRequest } from '../../../../src/types/api';
import { QwenTTSClient } from '../../../../src/tts/qwen-tts-client';
import type { TTSOptions } from '../../../../src/tts/types';

interface IntegrationWithTTSRequest extends ScenarioIntegrationRequest {
  tts?: {
    enabled: boolean;
    options?: TTSOptions;
  };
}

export async function POST(request: NextRequest) {
  try {
    const body: IntegrationWithTTSRequest = await request.json();
    const { integration, tts } = body;

    // シナリオ統合のバリデーション
    if (!integration || !integration.routeName || !integration.spots || !integration.sourceModel) {
      return NextResponse.json(
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
      return NextResponse.json(
        {
          success: false,
          error: 'QWEN_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    if (integrationLLM === 'gemini' && !geminiApiKey) {
      return NextResponse.json(
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
    const integrationResult = await integrator.integrate(integration);

    // TTSが有効な場合、音声合成を実行
    let ttsResult = null;
    if (tts?.enabled && integrationResult.integratedScript) {
      if (!qwenApiKey) {
        return NextResponse.json(
          {
            success: false,
            error: 'TTS機能にはQWEN_API_KEYが必要です',
          },
          { status: 500 }
        );
      }

      const ttsClient = new QwenTTSClient(qwenApiKey, qwenRegion);
      try {
        ttsResult = await ttsClient.synthesize(
          integrationResult.integratedScript,
          tts.options
        );
      } catch (ttsError) {
        console.error('TTS生成エラー:', ttsError);
        // TTSエラーは警告として扱い、統合結果は返す
        return NextResponse.json({
          success: true,
          data: {
            integration: integrationResult,
            tts: null,
            ttsError: ttsError instanceof Error ? ttsError.message : 'TTS生成に失敗しました',
          },
        });
      }
    }

    return NextResponse.json({
      success: true,
      data: {
        integration: integrationResult,
        tts: ttsResult,
      },
    });
  } catch (error) {
    console.error('シナリオ統合+TTSエラー:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'シナリオ統合+TTSに失敗しました',
      },
      { status: 500 }
    );
  }
}
