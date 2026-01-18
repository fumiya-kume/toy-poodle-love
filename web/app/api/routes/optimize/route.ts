import { NextRequest, NextResponse } from 'next/server';
import { GoogleRoutesClient } from '../../../../src/google-routes-client';
import {
  RouteOptimizationRequest,
  RouteOptimizationResponse,
} from '../../../../src/types/place-route';
import { getEnv, requireApiKey } from '../../../../src/config';

export async function POST(request: NextRequest) {
  try {
    const body: RouteOptimizationRequest = await request.json();
    const { origin, destination, intermediates, travelMode, optimizeWaypointOrder } = body;

    // バリデーション
    if (!origin) {
      return NextResponse.json<RouteOptimizationResponse>(
        {
          success: false,
          error: '出発地点（origin）が必要です',
        },
        { status: 400 }
      );
    }

    if (!destination) {
      return NextResponse.json<RouteOptimizationResponse>(
        {
          success: false,
          error: '目的地（destination）が必要です',
        },
        { status: 400 }
      );
    }

    if (!intermediates || !Array.isArray(intermediates)) {
      return NextResponse.json<RouteOptimizationResponse>(
        {
          success: false,
          error: '経由地点（intermediates）配列が必要です',
        },
        { status: 400 }
      );
    }

    const keyError = requireApiKey('googleMaps');
    if (keyError) return keyError;

    const env = getEnv();

    // ルート最適化実行
    const client = new GoogleRoutesClient(env.googleMapsApiKey!);
    const optimizedRoute = await client.optimizeRoute({
      origin,
      destination,
      intermediates,
      travelMode,
      optimizeWaypointOrder,
    });

    return NextResponse.json<RouteOptimizationResponse>({
      success: true,
      optimizedRoute,
    });
  } catch (error) {
    console.error('ルート最適化エラー:', error);
    return NextResponse.json<RouteOptimizationResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : 'ルート最適化に失敗しました',
      },
      { status: 500 }
    );
  }
}
