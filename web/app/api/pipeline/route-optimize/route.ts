/**
 * POST /api/pipeline/route-optimize
 * E2E Place-Route Optimization パイプライン API
 */

import { NextResponse } from 'next/server';
import { RouteOptimizerPipeline } from '../../../../src/pipeline/route-optimizer';
import { PipelineRequest } from '../../../../src/types/pipeline';

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
    const googleMapsApiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!googleMapsApiKey) {
      return NextResponse.json(
        { success: false, error: 'Google Maps API key is not configured' },
        { status: 500 }
      );
    }

    const qwenApiKey = process.env.QWEN_API_KEY;
    const geminiApiKey = process.env.GEMINI_API_KEY;

    if (pipelineRequest.model === 'qwen' && !qwenApiKey) {
      return NextResponse.json(
        { success: false, error: 'Qwen API key is not configured' },
        { status: 500 }
      );
    }

    if (pipelineRequest.model === 'gemini' && !geminiApiKey) {
      return NextResponse.json(
        { success: false, error: 'Gemini API key is not configured' },
        { status: 500 }
      );
    }

    // パイプライン実行
    const pipeline = new RouteOptimizerPipeline({
      qwenApiKey,
      geminiApiKey,
      googleMapsApiKey,
      qwenRegion: (process.env.QWEN_REGION as 'china' | 'international') || 'international',
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
