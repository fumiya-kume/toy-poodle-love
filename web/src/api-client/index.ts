/**
 * Taxi Scenario Writer API Client
 * TypeScript SDK for easy API integration
 */

import {
  GeocodeRequest,
  GeocodeResponse,
  RouteOptimizationRequest,
  RouteOptimizationResponse,
} from '../types/place-route';
import { PipelineRequest, PipelineResponse } from '../types/pipeline';
import {
  ScenarioRequest,
  ScenarioResponse,
  SpotScenarioRequest,
  SpotScenarioResponse,
  ScenarioIntegrationRequest,
  ScenarioIntegrationResponse,
  RouteGenerationRequest,
  RouteGenerationResponse,
} from '../types/api';

/**
 * API クライアント設定
 */
export interface ApiClientConfig {
  /** APIのベースURL（デフォルト: 空文字 = 相対パス） */
  baseUrl?: string;
  /** タイムアウト時間（ミリ秒、デフォルト: 30000） */
  timeout?: number;
}

/**
 * Taxi Scenario Writer API クライアント
 */
export class TaxiScenarioApiClient {
  private baseUrl: string;
  private timeout: number;

  constructor(config: ApiClientConfig = {}) {
    this.baseUrl = config.baseUrl || '';
    this.timeout = config.timeout || 30000;
  }

  /**
   * HTTP リクエストを実行する共通メソッド
   */
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(
          errorData.error || `HTTP ${response.status}: ${response.statusText}`
        );
      }

      return await response.json();
    } catch (error) {
      clearTimeout(timeoutId);
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('リクエストがタイムアウトしました');
      }
      throw error;
    }
  }

  // ==========================================
  // AI テキスト生成
  // ==========================================

  /**
   * Qwen AI でテキスト生成
   */
  async qwenChat(message: string): Promise<string> {
    const response = await this.request<{ response: string }>('/api/qwen', {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
    return response.response;
  }

  /**
   * Gemini AI でテキスト生成
   */
  async geminiChat(message: string): Promise<string> {
    const response = await this.request<{ response: string }>('/api/gemini', {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
    return response.response;
  }

  // ==========================================
  // Places & Routes
  // ==========================================

  /**
   * 住所をジオコーディング
   */
  async geocode(request: GeocodeRequest): Promise<GeocodeResponse> {
    return this.request<GeocodeResponse>('/api/places/geocode', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  /**
   * ルート最適化
   */
  async optimizeRoute(
    request: RouteOptimizationRequest
  ): Promise<RouteOptimizationResponse> {
    return this.request<RouteOptimizationResponse>('/api/routes/optimize', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  // ==========================================
  // パイプライン（E2E）
  // ==========================================

  /**
   * AI ルート最適化パイプライン
   * ルート生成 → ジオコーディング → ルート最適化 を一括実行
   */
  async pipelineRouteOptimize(
    request: PipelineRequest
  ): Promise<PipelineResponse> {
    return this.request<PipelineResponse>('/api/pipeline/route-optimize', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  // ==========================================
  // シナリオ生成
  // ==========================================

  /**
   * AI によるルート自動生成
   */
  async generateRoute(
    request: RouteGenerationRequest
  ): Promise<RouteGenerationResponse> {
    return this.request<RouteGenerationResponse>('/api/route/generate', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  /**
   * タクシーシナリオ生成
   */
  async generateScenario(
    request: ScenarioRequest
  ): Promise<ScenarioResponse> {
    return this.request<ScenarioResponse>('/api/scenario', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  /**
   * 単一地点のシナリオ生成
   */
  async generateSpotScenario(
    request: SpotScenarioRequest
  ): Promise<SpotScenarioResponse> {
    return this.request<SpotScenarioResponse>('/api/scenario/spot', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  /**
   * シナリオ統合
   */
  async integrateScenario(
    request: ScenarioIntegrationRequest
  ): Promise<ScenarioIntegrationResponse> {
    return this.request<ScenarioIntegrationResponse>(
      '/api/scenario/integrate',
      {
        method: 'POST',
        body: JSON.stringify(request),
      }
    );
  }

  // ==========================================
  // ヘルパーメソッド
  // ==========================================

  /**
   * 住所リストからルートを最適化（ジオコーディング + ルート最適化）
   */
  async optimizeRouteFromAddresses(
    addresses: string[],
    travelMode: 'DRIVE' | 'WALK' | 'BICYCLE' | 'TRANSIT' = 'DRIVE'
  ): Promise<RouteOptimizationResponse> {
    if (addresses.length < 2) {
      throw new Error('最低2つの住所が必要です');
    }

    // Step 1: ジオコーディング
    const geocodeResponse = await this.geocode({ addresses });

    if (!geocodeResponse.success || !geocodeResponse.places) {
      throw new Error(
        geocodeResponse.error || 'ジオコーディングに失敗しました'
      );
    }

    const places = geocodeResponse.places;

    if (places.length < 2) {
      throw new Error('有効な地点が2つ以上見つかりませんでした');
    }

    // Step 2: ルート最適化
    const origin = { placeId: places[0].placeId, name: places[0].inputAddress };
    const destination = {
      placeId: places[places.length - 1].placeId,
      name: places[places.length - 1].inputAddress,
    };
    const intermediates = places.slice(1, -1).map((p) => ({
      placeId: p.placeId,
      name: p.inputAddress,
    }));

    return this.optimizeRoute({
      origin,
      destination,
      intermediates,
      travelMode,
      optimizeWaypointOrder: true,
    });
  }

  /**
   * 距離をフォーマット（メートル → km/m）
   */
  formatDistance(meters: number): string {
    if (meters >= 1000) {
      return `${(meters / 1000).toFixed(1)} km`;
    }
    return `${meters} m`;
  }

  /**
   * 時間をフォーマット（秒 → 時間/分）
   */
  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) {
      return `${hours}時間${minutes}分`;
    }
    return `${minutes}分`;
  }
}

/**
 * デフォルトのAPIクライアントインスタンス
 */
export const apiClient = new TaxiScenarioApiClient();
