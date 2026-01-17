import { NextRequest, NextResponse } from 'next/server';
import { PlaceRoutePipeline } from '../../../../src/place-route/pipeline';
import { PlaceRoutePipelineRequest, PlaceRoutePipelineResponse } from '../../../../src/types/api';

export async function POST(request: NextRequest) {
  try {
    const body: PlaceRoutePipelineRequest = await request.json();
    const { input } = body;

    // バリデーション
    if (!input || !input.startPoint || !input.purpose) {
      return NextResponse.json<PlaceRoutePipelineResponse>(
        {
          success: false,
          error: '入力情報が不正です。startPointとpurposeが必要です',
        },
        { status: 400 }
      );
    }

    if (!input.spotCount || input.spotCount < 3 || input.spotCount > 8) {
      return NextResponse.json<PlaceRoutePipelineResponse>(
        {
          success: false,
          error: '地点数は3〜8の範囲で指定してください',
        },
        { status: 400 }
      );
    }

    if (!input.model || (input.model !== 'qwen' && input.model !== 'gemini')) {
      return NextResponse.json<PlaceRoutePipelineResponse>(
        {
          success: false,
          error: 'モデルはqwenまたはgeminiを指定してください',
        },
        { status: 400 }
      );
    }

    // 環境変数からAPIキーを取得
    const qwenApiKey = process.env.QWEN_API_KEY;
    const geminiApiKey = process.env.GEMINI_API_KEY;
    const googleMapsApiKey = process.env.GOOGLE_MAPS_API_KEY;
    const qwenRegion = (process.env.QWEN_REGION as 'china' | 'international') || 'international';

    // 必要なAPIキーが設定されているか確認
    if (input.model === 'qwen' && !qwenApiKey) {
      return NextResponse.json<PlaceRoutePipelineResponse>(
        {
          success: false,
          error: 'QWEN_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    if (input.model === 'gemini' && !geminiApiKey) {
      return NextResponse.json<PlaceRoutePipelineResponse>(
        {
          success: false,
          error: 'GEMINI_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    if (!googleMapsApiKey) {
      return NextResponse.json<PlaceRoutePipelineResponse>(
        {
          success: false,
          error: 'GOOGLE_MAPS_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    // パイプラインを初期化
    const pipeline = new PlaceRoutePipeline(
      qwenApiKey,
      geminiApiKey,
      googleMapsApiKey,
      qwenRegion
    );

    // パイプラインを実行
    const result = await pipeline.execute(input);

    // サマリーを生成
    const summary = PlaceRoutePipeline.createSummary(result);

    return NextResponse.json<PlaceRoutePipelineResponse>({
      success: result.success,
      data: result,
      summary: summary || undefined,
      error: result.error,
    });
  } catch (error) {
    console.error('パイプライン実行エラー:', error);
    return NextResponse.json<PlaceRoutePipelineResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : 'パイプラインの実行に失敗しました',
      },
      { status: 500 }
    );
  }
}
