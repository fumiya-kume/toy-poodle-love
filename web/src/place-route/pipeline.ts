/**
 * Place Route Pipeline
 * AIでスポットリストを生成 → ジオコーディング → ルート最適化
 * の一連のフローを統合したパイプライン
 */

import { RouteGenerator } from '../route/generator';
import { GooglePlacesClient } from '../google-places-client';
import { GoogleRoutesClient } from '../google-routes-client';
import { RouteWaypoint } from '../types/place-route';
import {
  PlaceRoutePipelineInput,
  PlaceRoutePipelineOutput,
  EnrichedSpot,
  OptimizedSpot,
  PipelineStepResult,
  RouteSummary,
} from '../types/place-route-pipeline';

export class PlaceRoutePipeline {
  private routeGenerator: RouteGenerator;
  private placesClient: GooglePlacesClient;
  private routesClient: GoogleRoutesClient;

  constructor(
    qwenApiKey?: string,
    geminiApiKey?: string,
    googleMapsApiKey?: string,
    qwenRegion?: 'china' | 'international'
  ) {
    this.routeGenerator = new RouteGenerator(qwenApiKey, geminiApiKey, qwenRegion);

    if (!googleMapsApiKey) {
      throw new Error('Google Maps API key is required for the pipeline');
    }
    this.placesClient = new GooglePlacesClient(googleMapsApiKey);
    this.routesClient = new GoogleRoutesClient(googleMapsApiKey);
  }

  /**
   * パイプラインを実行
   * Step 1: AIでスポットリストを生成
   * Step 2: 各スポットをジオコーディング
   * Step 3: ルートを最適化
   */
  async execute(input: PlaceRoutePipelineInput): Promise<PlaceRoutePipelineOutput> {
    const pipelineStartTime = Date.now();
    const result: PlaceRoutePipelineOutput = {
      success: false,
      generatedAt: new Date().toISOString(),
      aiGeneration: { success: false, processingTimeMs: 0 },
      geocoding: { success: false, processingTimeMs: 0 },
      routeOptimization: { success: false, processingTimeMs: 0 },
      totalProcessingTimeMs: 0,
      model: input.model,
    };

    // Step 1: AIでスポットリストを生成
    const aiResult = await this.executeAiGeneration(input);
    result.aiGeneration = aiResult;

    if (!aiResult.success || !aiResult.data) {
      result.error = `AI generation failed: ${aiResult.error}`;
      result.totalProcessingTimeMs = Date.now() - pipelineStartTime;
      return result;
    }

    result.routeName = aiResult.data.spots[0]?.name
      ? `${input.startPoint}発 ${input.purpose}`
      : undefined;

    // Step 2: ジオコーディング
    const geocodeResult = await this.executeGeocoding(aiResult.data.spots);
    result.geocoding = geocodeResult;

    if (!geocodeResult.success || !geocodeResult.data) {
      result.error = `Geocoding failed: ${geocodeResult.error}`;
      result.totalProcessingTimeMs = Date.now() - pipelineStartTime;
      return result;
    }

    // ジオコーディングに成功したスポットが2つ未満の場合はルート最適化をスキップ
    const geocodedSpots = geocodeResult.data.spots.filter((s) => s.geocoded);
    if (geocodedSpots.length < 2) {
      result.error = 'Not enough geocoded spots to create a route (need at least 2)';
      result.totalProcessingTimeMs = Date.now() - pipelineStartTime;
      return result;
    }

    // Step 3: ルート最適化
    const routeResult = await this.executeRouteOptimization(
      geocodeResult.data.spots,
      input.travelMode,
      input.optimizeWaypointOrder
    );
    result.routeOptimization = routeResult;

    if (routeResult.success) {
      result.success = true;
    } else {
      result.error = `Route optimization failed: ${routeResult.error}`;
    }

    result.totalProcessingTimeMs = Date.now() - pipelineStartTime;
    return result;
  }

  /**
   * Step 1: AIでスポットリストを生成
   */
  private async executeAiGeneration(
    input: PlaceRoutePipelineInput
  ): Promise<PipelineStepResult<{ spots: EnrichedSpot[] }>> {
    const startTime = Date.now();

    try {
      const generated = await this.routeGenerator.generate({
        startPoint: input.startPoint,
        purpose: input.purpose,
        spotCount: input.spotCount,
        language: input.language,
        model: input.model,
      });

      const enrichedSpots: EnrichedSpot[] = generated.spots.map((spot) => ({
        name: spot.name,
        type: spot.type,
        description: spot.description,
        point: spot.point,
        generatedNote: spot.generatedNote,
      }));

      return {
        success: true,
        data: { spots: enrichedSpots },
        processingTimeMs: Date.now() - startTime,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        processingTimeMs: Date.now() - startTime,
      };
    }
  }

  /**
   * Step 2: 各スポットをジオコーディング
   */
  private async executeGeocoding(
    spots: EnrichedSpot[]
  ): Promise<PipelineStepResult<{ successCount: number; failedCount: number; spots: EnrichedSpot[] }>> {
    const startTime = Date.now();

    try {
      // 各スポットを並列でジオコーディング
      const geocodePromises = spots.map(async (spot) => {
        try {
          // スポット名を使ってジオコーディング
          const geocoded = await this.placesClient.geocode(spot.name);
          return { ...spot, geocoded };
        } catch (error) {
          return {
            ...spot,
            geocodeError: error instanceof Error ? error.message : 'Geocoding failed',
          };
        }
      });

      const enrichedSpots = await Promise.all(geocodePromises);
      const successCount = enrichedSpots.filter((s) => s.geocoded).length;
      const failedCount = enrichedSpots.filter((s) => s.geocodeError).length;

      return {
        success: successCount > 0,
        data: { successCount, failedCount, spots: enrichedSpots },
        processingTimeMs: Date.now() - startTime,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        processingTimeMs: Date.now() - startTime,
      };
    }
  }

  /**
   * Step 3: ルートを最適化
   */
  private async executeRouteOptimization(
    spots: EnrichedSpot[],
    travelMode?: 'DRIVE' | 'WALK' | 'BICYCLE' | 'TRANSIT',
    optimizeWaypointOrder?: boolean
  ): Promise<
    PipelineStepResult<{
      optimizedSpots: OptimizedSpot[];
      legs: { fromIndex: number; toIndex: number; distanceMeters: number; durationSeconds: number }[];
      totalDistanceMeters: number;
      totalDurationSeconds: number;
    }>
  > {
    const startTime = Date.now();

    try {
      // ジオコーディングに成功したスポットのみを使用
      const geocodedSpots = spots.filter((s) => s.geocoded);

      if (geocodedSpots.length < 2) {
        return {
          success: false,
          error: 'Need at least 2 geocoded spots for route optimization',
          processingTimeMs: Date.now() - startTime,
        };
      }

      // 最初と最後のスポットを出発地と目的地とする
      const origin = this.spotToWaypoint(geocodedSpots[0]);
      const destination = this.spotToWaypoint(geocodedSpots[geocodedSpots.length - 1]);
      const intermediates =
        geocodedSpots.length > 2
          ? geocodedSpots.slice(1, -1).map((s) => this.spotToWaypoint(s))
          : [];

      const optimized = await this.routesClient.optimizeRoute({
        origin,
        destination,
        intermediates,
        travelMode: travelMode || 'DRIVE',
        optimizeWaypointOrder: optimizeWaypointOrder !== false,
      });

      // 最適化された順序でスポットを並べ替え
      const optimizedSpots: OptimizedSpot[] = optimized.orderedWaypoints.map((ow, index) => {
        let originalSpot: EnrichedSpot;

        if (ow.originalIndex === -1) {
          // 出発地点
          originalSpot = geocodedSpots[0];
        } else if (ow.originalIndex === -2) {
          // 目的地
          originalSpot = geocodedSpots[geocodedSpots.length - 1];
        } else {
          // 経由地点
          originalSpot = geocodedSpots[ow.originalIndex + 1];
        }

        const leg = optimized.legs[index];
        return {
          ...originalSpot,
          optimizedOrder: index,
          distanceToNextMeters: leg?.distanceMeters,
          durationToNextSeconds: leg?.durationSeconds,
        };
      });

      return {
        success: true,
        data: {
          optimizedSpots,
          legs: optimized.legs,
          totalDistanceMeters: optimized.totalDistanceMeters,
          totalDurationSeconds: optimized.totalDurationSeconds,
        },
        processingTimeMs: Date.now() - startTime,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        processingTimeMs: Date.now() - startTime,
      };
    }
  }

  /**
   * EnrichedSpot を RouteWaypoint に変換
   */
  private spotToWaypoint(spot: EnrichedSpot): RouteWaypoint {
    if (spot.geocoded) {
      return {
        name: spot.name,
        placeId: spot.geocoded.placeId,
        location: spot.geocoded.location,
      };
    }
    return {
      name: spot.name,
      address: spot.name,
    };
  }

  /**
   * パイプライン結果からサマリーを生成
   */
  static createSummary(output: PlaceRoutePipelineOutput): RouteSummary | null {
    if (!output.success || !output.routeOptimization.data) {
      return null;
    }

    const { optimizedSpots, totalDistanceMeters, totalDurationSeconds } =
      output.routeOptimization.data;

    return {
      routeName: output.routeName || 'Unnamed Route',
      spotCount: optimizedSpots.length,
      totalDistanceMeters,
      totalDistanceText: formatDistance(totalDistanceMeters),
      totalDurationSeconds,
      totalDurationText: formatDuration(totalDurationSeconds),
      spots: optimizedSpots.map((spot) => ({
        order: spot.optimizedOrder,
        name: spot.name,
        type: spot.type,
        address: spot.geocoded?.formattedAddress,
        distanceToNextText: spot.distanceToNextMeters
          ? formatDistance(spot.distanceToNextMeters)
          : undefined,
        durationToNextText: spot.durationToNextSeconds
          ? formatDuration(spot.durationToNextSeconds)
          : undefined,
      })),
    };
  }
}

/**
 * 距離をフォーマット（メートル → km/m）
 */
function formatDistance(meters: number): string {
  if (meters >= 1000) {
    return `${(meters / 1000).toFixed(1)} km`;
  }
  return `${meters} m`;
}

/**
 * 時間をフォーマット（秒 → 時間/分）
 */
function formatDuration(seconds: number): string {
  if (seconds >= 3600) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return minutes > 0 ? `${hours}時間${minutes}分` : `${hours}時間`;
  }
  if (seconds >= 60) {
    return `${Math.floor(seconds / 60)}分`;
  }
  return `${seconds}秒`;
}
