/**
 * Google Routes API クライアント
 * 経由地点の巡回順序を最適化する
 */

import {
  RouteWaypoint,
  RouteOptimizationRequest,
  OptimizedWaypoint,
  RouteLeg,
  LatLng,
} from './types/place-route';

interface RoutesApiWaypoint {
  via?: boolean;
  vehicleStopover?: boolean;
  sideOfRoad?: boolean;
  location?: {
    latLng: {
      latitude: number;
      longitude: number;
    };
  };
  placeId?: string;
  address?: string;
}

interface RoutesApiRequest {
  origin: RoutesApiWaypoint;
  destination: RoutesApiWaypoint;
  intermediates?: RoutesApiWaypoint[];
  travelMode: string;
  routingPreference?: string;
  computeAlternativeRoutes?: boolean;
  optimizeWaypointOrder?: boolean;
}

interface RoutesApiLeg {
  distanceMeters: number;
  duration: string; // "123s" 形式
  startLocation?: {
    latLng: {
      latitude: number;
      longitude: number;
    };
  };
  endLocation?: {
    latLng: {
      latitude: number;
      longitude: number;
    };
  };
}

interface RoutesApiResponse {
  routes?: Array<{
    legs: RoutesApiLeg[];
    distanceMeters: number;
    duration: string;
    optimizedIntermediateWaypointIndex?: number[];
  }>;
}

export class GoogleRoutesClient {
  private apiKey: string;
  private baseUrl = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  constructor(apiKey: string) {
    if (!apiKey) {
      throw new Error('Google Maps API key is required');
    }
    this.apiKey = apiKey;
  }

  /**
   * 経由地点の巡回順序を最適化してルートを計算
   */
  async optimizeRoute(
    request: RouteOptimizationRequest
  ): Promise<{
    orderedWaypoints: OptimizedWaypoint[];
    legs: RouteLeg[];
    totalDistanceMeters: number;
    totalDurationSeconds: number;
  }> {
    const fieldMask = [
      'routes.legs.distanceMeters',
      'routes.legs.duration',
      'routes.distanceMeters',
      'routes.duration',
      'routes.optimizedIntermediateWaypointIndex',
    ].join(',');

    const apiRequest: RoutesApiRequest = {
      origin: this.toApiWaypoint(request.origin),
      destination: this.toApiWaypoint(request.destination),
      intermediates: request.intermediates.map((wp) => this.toApiWaypoint(wp)),
      travelMode: request.travelMode || 'DRIVE',
      optimizeWaypointOrder: request.optimizeWaypointOrder !== false, // デフォルト true
    };

    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': this.apiKey,
        'X-Goog-FieldMask': fieldMask,
      },
      body: JSON.stringify(apiRequest),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Routes API error: ${response.status} - ${errorText}`);
    }

    const data: RoutesApiResponse = await response.json();

    if (!data.routes || data.routes.length === 0) {
      throw new Error('No routes found');
    }

    const route = data.routes[0];
    const optimizedOrder = route.optimizedIntermediateWaypointIndex ||
      request.intermediates.map((_, i) => i); // 最適化なしの場合は元の順序

    // 最適化された順序で地点を並べ替え
    const orderedWaypoints: OptimizedWaypoint[] = [
      // 出発地点
      {
        originalIndex: -1, // 特別な値：出発地点
        optimizedOrder: 0,
        waypoint: request.origin,
      },
      // 最適化された経由地点
      ...optimizedOrder.map((originalIdx, newOrder) => ({
        originalIndex: originalIdx,
        optimizedOrder: newOrder + 1,
        waypoint: request.intermediates[originalIdx],
      })),
      // 目的地
      {
        originalIndex: -2, // 特別な値：目的地
        optimizedOrder: optimizedOrder.length + 1,
        waypoint: request.destination,
      },
    ];

    // 各区間の情報を取得
    const legs: RouteLeg[] = route.legs.map((leg, index) => ({
      fromIndex: index,
      toIndex: index + 1,
      distanceMeters: leg.distanceMeters,
      durationSeconds: this.parseDuration(leg.duration),
    }));

    return {
      orderedWaypoints,
      legs,
      totalDistanceMeters: route.distanceMeters,
      totalDurationSeconds: this.parseDuration(route.duration),
    };
  }

  /**
   * RouteWaypoint を API 形式に変換
   */
  private toApiWaypoint(waypoint: RouteWaypoint): RoutesApiWaypoint {
    if (waypoint.placeId) {
      return { placeId: waypoint.placeId };
    }
    if (waypoint.location) {
      return {
        location: {
          latLng: {
            latitude: waypoint.location.latitude,
            longitude: waypoint.location.longitude,
          },
        },
      };
    }
    if (waypoint.address) {
      return { address: waypoint.address };
    }
    throw new Error('Waypoint must have placeId, location, or address');
  }

  /**
   * "123s" 形式の duration を秒数に変換
   */
  private parseDuration(duration: string): number {
    const match = duration.match(/^(\d+)s$/);
    if (match) {
      return parseInt(match[1], 10);
    }
    return 0;
  }
}
