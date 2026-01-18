/**
 * POST /api/pipeline/route-optimize
 * E2E Place-Route Optimization パイプライン API
 */

import { NextResponse } from 'next/server';
import { RouteOptimizerPipeline } from '../../../../src/pipeline/route-optimizer';
import { PipelineRequest } from '../../../../src/types/pipeline';
import { getEnv, requireApiKey } from '../../../../src/config';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // 入力バリデーション
    const validationError = validateRequest(body);
    if (validationError) {
      return NextResponse.json(
        { success: false, error: validationError },
        { status: 400 }
      );
    }

    const pipelineRequest: PipelineRequest = {
      startPoint: body.startPoint,
      purpose: body.purpose,
      spotCount: body.spotCount,
      model: body.model,
    };

    // 環境変数チェック
    const googleMapsKeyError = requireApiKey('googleMaps');
    if (googleMapsKeyError) return googleMapsKeyError;

    if (pipelineRequest.model === 'qwen') {
      const keyError = requireApiKey('qwen');
      if (keyError) return keyError;
    }

    if (pipelineRequest.model === 'gemini') {
      const keyError = requireApiKey('gemini');
      if (keyError) return keyError;
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

    return NextResponse.json(result);

  } catch (error) {
    console.error('Pipeline API error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error',
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
