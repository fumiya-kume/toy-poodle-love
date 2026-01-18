/**
 * E2E Place-Route Optimization パイプラインサービス
 * AI生成 → ジオコーディング → ルート最適化を一貫して実行
 */

import { RouteGenerator } from '../route/generator';
import { GooglePlacesClient } from '../google-places-client';
import { GoogleRoutesClient } from '../google-routes-client';
import {
  PipelineRequest,
  PipelineResponse,
  RouteGenerationStepResult,
  GeocodingStepResult,
  RouteOptimizationStepResult,
} from '../types/pipeline';
import { GeocodedPlace } from '../types/place-route';
import { GeneratedRouteSpot } from '../types/route';

interface RouteOptimizerConfig {
  qwenApiKey?: string;
  geminiApiKey?: string;
  googleMapsApiKey: string;
  qwenRegion?: 'china' | 'international';
}

export class RouteOptimizerPipeline {
  private routeGenerator: RouteGenerator;
  private placesClient: GooglePlacesClient;
  private routesClient: GoogleRoutesClient;

  constructor(config: RouteOptimizerConfig) {
    this.routeGenerator = new RouteGenerator(
      config.qwenApiKey,
      config.geminiApiKey,
      config.qwenRegion
    );
    this.placesClient = new GooglePlacesClient(config.googleMapsApiKey);
    this.routesClient = new GoogleRoutesClient(config.googleMapsApiKey);
  }

  /**
   * E2Eパイプラインを実行
   */
  async execute(request: PipelineRequest): Promise<PipelineResponse> {
    const pipelineStartTime = Date.now();

    const response: PipelineResponse = {
      success: false,
      request,
      routeGeneration: { status: 'pending' },
      geocoding: { status: 'pending' },
      routeOptimization: { status: 'pending' },
      totalProcessingTimeMs: 0,
    };

    try {
      // Step 1: AIルート生成
      response.routeGeneration = await this.executeRouteGeneration(request);
      if (response.routeGeneration.status === 'failed') {
        response.error = response.routeGeneration.error;
        response.totalProcessingTimeMs = Date.now() - pipelineStartTime;
        return response;
      }

      const spots = response.routeGeneration.spots!;

      // Step 2: ジオコーディング
      response.geocoding = await this.executeGeocoding(spots);
      if (response.geocoding.status === 'failed') {
        response.error = response.geocoding.error;
        response.totalProcessingTimeMs = Date.now() - pipelineStartTime;
        return response;
      }

      const places = response.geocoding.places!;

      // Step 3: ルート最適化
      response.routeOptimization = await this.executeRouteOptimization(places, spots);
      if (response.routeOptimization.status === 'failed') {
        response.error = response.routeOptimization.error;
        response.totalProcessingTimeMs = Date.now() - pipelineStartTime;
        return response;
      }

      response.success = true;
      response.totalProcessingTimeMs = Date.now() - pipelineStartTime;
      return response;

    } catch (error) {
      response.error = error instanceof Error ? error.message : 'Unknown error occurred';
      response.totalProcessingTimeMs = Date.now() - pipelineStartTime;
      return response;
    }
  }

  /**
   * Step 1: AIルート生成
   */
  private async executeRouteGeneration(request: PipelineRequest): Promise<RouteGenerationStepResult> {
    const stepStartTime = Date.now();

    try {
      const result = await this.routeGenerator.generate({
        startPoint: request.startPoint,
        purpose: request.purpose,
        spotCount: request.spotCount,
        model: request.model,
      });

      return {
        status: 'completed',
        routeName: result.routeName,
        spots: result.spots,
        processingTimeMs: Date.now() - stepStartTime,
      };
    } catch (error) {
      return {
        status: 'failed',
        error: error instanceof Error ? error.message : 'AI route generation failed',
        processingTimeMs: Date.now() - stepStartTime,
      };
    }
  }

  /**
   * Step 2: ジオコーディング
   */
  private async executeGeocoding(spots: GeneratedRouteSpot[]): Promise<GeocodingStepResult> {
    const stepStartTime = Date.now();

    try {
      // spotのnameからアドレスリストを作成
      // pointがあればpoint（より具体的な住所）を優先
      const addresses = spots.map(spot => spot.point || spot.name);

      const places = await this.placesClient.geocodeBatch(addresses);

      // 失敗したスポットを特定
      const successfulAddresses = new Set(places.map(p => p.inputAddress));
      const failedSpots = addresses.filter(addr => !successfulAddresses.has(addr));

      if (places.length < 2) {
        return {
          status: 'failed',
          places,
          failedSpots,
          error: 'Valid places found are less than 2, cannot create route',
          processingTimeMs: Date.now() - stepStartTime,
        };
      }

      return {
        status: 'completed',
        places,
        failedSpots: failedSpots.length > 0 ? failedSpots : undefined,
        processingTimeMs: Date.now() - stepStartTime,
      };
    } catch (error) {
      return {
        status: 'failed',
        error: error instanceof Error ? error.message : 'Geocoding failed',
        processingTimeMs: Date.now() - stepStartTime,
      };
    }
  }

  /**
   * Step 3: ルート最適化
   */
  private async executeRouteOptimization(
    places: GeocodedPlace[],
    spots: GeneratedRouteSpot[]
  ): Promise<RouteOptimizationStepResult> {
    const stepStartTime = Date.now();

    try {
      // 地点名とplaceIdのマッピングを作成
      const placeMap = new Map<string, GeocodedPlace>();
      places.forEach(place => {
        placeMap.set(place.inputAddress, place);
      });

      // spotsの順序に基づいてplacesを並べ直し
      // （一部のスポットがジオコードに失敗している可能性があるため）
      const orderedPlaces: GeocodedPlace[] = [];
      for (const spot of spots) {
        const address = spot.point || spot.name;
        const place = placeMap.get(address);
        if (place) {
          orderedPlaces.push(place);
        }
      }

      if (orderedPlaces.length < 2) {
        return {
          status: 'failed',
          error: 'Not enough valid places for route optimization',
          processingTimeMs: Date.now() - stepStartTime,
        };
      }

      // 最初を出発地、最後を目的地、中間を経由地点として最適化
      const origin = {
        placeId: orderedPlaces[0].placeId,
        name: orderedPlaces[0].inputAddress,
      };
      const destination = {
        placeId: orderedPlaces[orderedPlaces.length - 1].placeId,
        name: orderedPlaces[orderedPlaces.length - 1].inputAddress,
      };
      const intermediates = orderedPlaces.slice(1, -1).map(place => ({
        placeId: place.placeId,
        name: place.inputAddress,
      }));

      const result = await this.routesClient.optimizeRoute({
        origin,
        destination,
        intermediates,
        travelMode: 'DRIVE',
        optimizeWaypointOrder: true,
      });

      return {
        status: 'completed',
        orderedWaypoints: result.orderedWaypoints,
        legs: result.legs,
        totalDistanceMeters: result.totalDistanceMeters,
        totalDurationSeconds: result.totalDurationSeconds,
        processingTimeMs: Date.now() - stepStartTime,
      };
    } catch (error) {
      return {
        status: 'failed',
        error: error instanceof Error ? error.message : 'Route optimization failed',
        processingTimeMs: Date.now() - stepStartTime,
      };
    }
  }
}
