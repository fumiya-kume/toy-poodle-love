/**
 * POST /api/pipeline/route-optimize
 * E2E Place-Route Optimization パイプライン API
 */

import { NextResponse } from 'next/server';
import { RouteOptimizerPipeline } from '../../../../src/pipeline/route-optimizer';
import { PipelineRequest } from '../../../../src/types/pipeline';
import { getEnv, requireApiKey } from '../../../../src/config';
import { createPipelineTrace } from '../../../../src/langfuse-client';

export async function POST(request: Request) {
  // Langfuseトレースを開始（リクエストボディ解析前に開始）
  const trace = createPipelineTrace('route-optimize-pipeline');

  try {
    // JSON解析とバリデーション
    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch (error) {
      const errorMessage = 'Invalid JSON in request body';
      await trace?.end({ error: errorMessage }).catch(() => {});
      return NextResponse.json(
        { success: false, error: errorMessage },
        { status: 400 }
      );
    }

    // 入力バリデーション
    const validationError = validateRequest(body);
    if (validationError) {
      await trace?.end({ error: validationError }).catch(() => {});
      return NextResponse.json(
        { success: false, error: validationError },
        { status: 400 }
      );
    }

    const pipelineRequest: PipelineRequest = {
      startPoint: body.startPoint as string,
      purpose: body.purpose as string,
      spotCount: body.spotCount as number,
      model: body.model as 'qwen' | 'gemini',
    };

    // トレースにメタデータを更新
    trace?.trace?.update({
      input: {
        startPoint: pipelineRequest.startPoint,
        purpose: pipelineRequest.purpose,
        spotCount: pipelineRequest.spotCount,
        model: pipelineRequest.model,
      },
    });

    // 環境変数チェック
    const googleMapsKeyError = requireApiKey('googleMaps');
    if (googleMapsKeyError) {
      const errorMessage = 'GOOGLE_MAPS_API_KEY is not configured';
      await trace?.end({ error: errorMessage }).catch(() => {});
      return googleMapsKeyError;
    }

    if (pipelineRequest.model === 'qwen') {
      const keyError = requireApiKey('qwen');
      if (keyError) {
        const errorMessage = 'QWEN_API_KEY is not configured';
        await trace?.end({ error: errorMessage }).catch(() => {});
        return keyError;
      }
    }

    if (pipelineRequest.model === 'gemini') {
      const keyError = requireApiKey('gemini');
      if (keyError) {
        const errorMessage = 'GEMINI_API_KEY is not configured';
        await trace?.end({ error: errorMessage }).catch(() => {});
        return keyError;
      }
    }

    const env = getEnv();

    // パイプライン実行
    const pipeline = new RouteOptimizerPipeline({
      qwenApiKey: env.qwenApiKey,
      geminiApiKey: env.geminiApiKey,
      googleMapsApiKey: env.googleMapsApiKey!,
      qwenRegion: env.qwenRegion,
    });

    const result = await pipeline.execute(pipelineRequest);

    // トレースを終了
    await trace?.end({ success: result.success, result }).catch(() => {});

    return NextResponse.json(result);

  } catch (error) {
    console.error('Pipeline API error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Internal server error';
    
    // エラーをトレースに記録
    await trace?.end({ error: errorMessage }).catch(() => {});

    return NextResponse.json(
      {
        success: false,
        error: errorMessage,
      },
      { status: 500 }
    );
  }
}

function validateRequest(body: Record<string, unknown>): string | null {
  if (!body.startPoint || typeof body.startPoint !== 'string') {
    return 'startPoint is required and must be a string';
  }

  if (!body.purpose || typeof body.purpose !== 'string') {
    return 'purpose is required and must be a string';
  }

  if (!body.spotCount || typeof body.spotCount !== 'number') {
    return 'spotCount is required and must be a number';
  }

  if (body.spotCount < 3 || body.spotCount > 8) {
    return 'spotCount must be between 3 and 8';
  }

  if (!body.model || (body.model !== 'qwen' && body.model !== 'gemini')) {
    return 'model is required and must be either "qwen" or "gemini"';
  }

  return null;
}
