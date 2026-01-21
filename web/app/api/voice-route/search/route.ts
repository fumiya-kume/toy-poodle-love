/**
 * 音声認識テキストからルート検索を実行する統合APIエンドポイント
 *
 * POST /api/voice-route/search
 *
 * 処理フロー:
 * 1. 音声認識テキストからLLMで出発地・目的地を抽出
 * 2. 抽出した地点をジオコーディング
 * 3. ルート検索を実行
 *
 * Request Body:
 *   - text: string (音声認識で得られたテキスト)
 *   - model?: 'qwen' | 'gemini' (使用するLLMモデル)
 *
 * Response:
 *   - success: boolean
 *   - extractedLocation?: ExtractedLocation
 *   - geocodedPlaces?: { origin, destination, waypoints }
 *   - route?: { totalDistanceMeters, totalDurationSeconds, legs }
 *   - error?: string
 */

import { NextResponse } from 'next/server';
import { LocationExtractor } from '../../../../src/location-extractor';
import { GooglePlacesClient } from '../../../../src/google-places-client';
import { GoogleRoutesClient } from '../../../../src/google-routes-client';
import { getEnv } from '../../../../src/config';
import type { VoiceRouteSearchRequest, VoiceRouteSearchResponse } from '../../../../src/types/voice-route';
import type { GeocodedPlace } from '../../../../src/types/place-route';

export async function POST(request: Request) {
  try {
    const body: VoiceRouteSearchRequest = await request.json();

    // バリデーション
    if (!body.text || typeof body.text !== 'string' || body.text.trim().length === 0) {
      return NextResponse.json<VoiceRouteSearchResponse>({
        success: false,
        error: 'テキストが必要です',
      }, { status: 400 });
    }

    const model = body.model || 'gemini';
    if (model !== 'qwen' && model !== 'gemini') {
      return NextResponse.json<VoiceRouteSearchResponse>({
        success: false,
        error: 'モデルは "qwen" または "gemini" を指定してください',
      }, { status: 400 });
    }

    console.log('Voice route search starting:', {
      textLength: body.text.length,
      textPreview: body.text.substring(0, 100),
      model,
    });

    // Step 1: 地点抽出
    const extractor = new LocationExtractor();
    const extractedLocation = await extractor.extract(body.text, model);

    console.log('Step 1 - Location extracted:', extractedLocation);

    // 出発地と目的地が両方とも取得できない場合はエラー
    if (!extractedLocation.origin && !extractedLocation.destination) {
      return NextResponse.json<VoiceRouteSearchResponse>({
        success: false,
        extractedLocation,
        error: '出発地または目的地を特定できませんでした。もう一度話してください。',
      });
    }

    // Step 2: ジオコーディング
    const env = getEnv();
    if (!env.googleMapsApiKey) {
      return NextResponse.json<VoiceRouteSearchResponse>({
        success: false,
        extractedLocation,
        error: 'Google APIキーが設定されていません',
      }, { status: 500 });
    }

    const placesClient = new GooglePlacesClient(env.googleMapsApiKey);
    const geocodedPlaces: {
      origin?: GeocodedPlace;
      destination?: GeocodedPlace;
      waypoints?: GeocodedPlace[];
    } = {};

    // 出発地をジオコード
    if (extractedLocation.origin) {
      try {
        const originPlace = await placesClient.geocode(extractedLocation.origin);
        if (originPlace) {
          geocodedPlaces.origin = originPlace;
        }
      } catch (error) {
        console.error('Origin geocoding failed:', error);
      }
    }

    // 目的地をジオコード
    if (extractedLocation.destination) {
      try {
        const destPlace = await placesClient.geocode(extractedLocation.destination);
        if (destPlace) {
          geocodedPlaces.destination = destPlace;
        }
      } catch (error) {
        console.error('Destination geocoding failed:', error);
      }
    }

    // 経由地点をジオコード
    if (extractedLocation.waypoints.length > 0) {
      try {
        const waypointPlaces = await placesClient.geocodeBatch(extractedLocation.waypoints);
        geocodedPlaces.waypoints = waypointPlaces;
      } catch (error) {
        console.error('Waypoints geocoding failed:', error);
      }
    }

    console.log('Step 2 - Geocoding complete:', {
      hasOrigin: !!geocodedPlaces.origin,
      hasDestination: !!geocodedPlaces.destination,
      waypointsCount: geocodedPlaces.waypoints?.length || 0,
    });

    // 出発地も目的地もジオコードできなかった場合
    if (!geocodedPlaces.origin && !geocodedPlaces.destination) {
      return NextResponse.json<VoiceRouteSearchResponse>({
        success: false,
        extractedLocation,
        error: '地点の座標を取得できませんでした。地名をより具体的に話してください。',
      });
    }

    // Step 3: ルート検索（出発地と目的地の両方がある場合のみ）
    if (geocodedPlaces.origin && geocodedPlaces.destination) {
      try {
        const routesClient = new GoogleRoutesClient(env.googleMapsApiKey);

        const routeResult = await routesClient.optimizeRoute({
          origin: {
            placeId: geocodedPlaces.origin.placeId,
            name: geocodedPlaces.origin.formattedAddress,
          },
          destination: {
            placeId: geocodedPlaces.destination.placeId,
            name: geocodedPlaces.destination.formattedAddress,
          },
          intermediates: geocodedPlaces.waypoints?.map(wp => ({
            placeId: wp.placeId,
            name: wp.formattedAddress,
          })) || [],
          travelMode: 'DRIVE',
          optimizeWaypointOrder: true,
        });

        console.log('Step 3 - Route search complete:', {
          totalDistance: routeResult.totalDistanceMeters,
          totalDuration: routeResult.totalDurationSeconds,
          legsCount: routeResult.legs.length,
        });

        return NextResponse.json<VoiceRouteSearchResponse>({
          success: true,
          extractedLocation,
          geocodedPlaces,
          route: {
            totalDistanceMeters: routeResult.totalDistanceMeters,
            totalDurationSeconds: routeResult.totalDurationSeconds,
            legs: routeResult.legs,
          },
        });

      } catch (error) {
        console.error('Route search failed:', error);
        // ルート検索に失敗してもジオコーディング結果は返す
        return NextResponse.json<VoiceRouteSearchResponse>({
          success: true,
          extractedLocation,
          geocodedPlaces,
          error: 'ルート検索に失敗しました: ' + (error instanceof Error ? error.message : '不明なエラー'),
        });
      }
    }

    // 出発地または目的地のどちらかしかない場合
    return NextResponse.json<VoiceRouteSearchResponse>({
      success: true,
      extractedLocation,
      geocodedPlaces,
    });

  } catch (error) {
    console.error('Voice route search error:', error);

    const errorMessage = error instanceof Error ? error.message : 'ルート検索に失敗しました';

    return NextResponse.json<VoiceRouteSearchResponse>({
      success: false,
      error: errorMessage,
    }, { status: 500 });
  }
}
