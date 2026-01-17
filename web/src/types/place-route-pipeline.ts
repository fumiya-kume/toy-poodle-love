/**
 * Place Route Pipeline - 統合パイプラインの型定義
 * AIでスポットリストを生成 → ジオコーディング → ルート最適化
 */

import { LatLng, GeocodedPlace, RouteLeg, RouteWaypoint } from './place-route';
import { OutputLanguage } from './scenario';

/**
 * パイプライン入力パラメータ
 */
export interface PlaceRoutePipelineInput {
  /** スタート地点（例: 東京駅） */
  startPoint: string;
  /** 目的・テーマ（例: 皇居周辺を観光したい） */
  purpose: string;
  /** 生成する地点数（3-8） */
  spotCount: number;
  /** 出力言語（省略時はauto） */
  language?: OutputLanguage;
  /** 使用するAIモデル */
  model: 'qwen' | 'gemini';
  /** 移動モード（省略時はDRIVE） */
  travelMode?: 'DRIVE' | 'WALK' | 'BICYCLE' | 'TRANSIT';
  /** 経由地点の順序を最適化するか（省略時はtrue） */
  optimizeWaypointOrder?: boolean;
}

/**
 * AIが生成したスポット + ジオコーディング情報
 */
export interface EnrichedSpot {
  /** スポット名 */
  name: string;
  /** タイプ */
  type: 'start' | 'waypoint' | 'destination';
  /** AIが生成した説明 */
  description?: string;
  /** AIが生成したポイント */
  point?: string;
  /** AIが生成した補足情報 */
  generatedNote?: string;
  /** ジオコーディング結果 */
  geocoded?: GeocodedPlace;
  /** ジオコーディングに失敗した場合のエラー */
  geocodeError?: string;
}

/**
 * 最適化されたルートのスポット（移動情報付き）
 */
export interface OptimizedSpot extends EnrichedSpot {
  /** 最適化後の順序（0から始まる） */
  optimizedOrder: number;
  /** 次のスポットへの移動距離（メートル） */
  distanceToNextMeters?: number;
  /** 次のスポットへの移動時間（秒） */
  durationToNextSeconds?: number;
}

/**
 * パイプラインの各ステップの結果
 */
export interface PipelineStepResult<T> {
  /** 成功したか */
  success: boolean;
  /** 結果データ */
  data?: T;
  /** エラーメッセージ */
  error?: string;
  /** 処理時間（ミリ秒） */
  processingTimeMs: number;
}

/**
 * パイプライン出力
 */
export interface PlaceRoutePipelineOutput {
  /** 成功したか */
  success: boolean;
  /** 生成日時 */
  generatedAt: string;
  /** 生成されたルート名 */
  routeName?: string;

  /** Step 1: AI生成の結果 */
  aiGeneration: PipelineStepResult<{
    spots: EnrichedSpot[];
  }>;

  /** Step 2: ジオコーディングの結果 */
  geocoding: PipelineStepResult<{
    successCount: number;
    failedCount: number;
    spots: EnrichedSpot[];
  }>;

  /** Step 3: ルート最適化の結果 */
  routeOptimization: PipelineStepResult<{
    optimizedSpots: OptimizedSpot[];
    legs: RouteLeg[];
    totalDistanceMeters: number;
    totalDurationSeconds: number;
  }>;

  /** 全体の処理時間（ミリ秒） */
  totalProcessingTimeMs: number;
  /** 使用したモデル */
  model: 'qwen' | 'gemini';
  /** エラーメッセージ（全体が失敗した場合） */
  error?: string;
}

/**
 * ルートのサマリー情報（表示用）
 */
export interface RouteSummary {
  /** ルート名 */
  routeName: string;
  /** スポット数 */
  spotCount: number;
  /** 総距離（メートル） */
  totalDistanceMeters: number;
  /** 総距離（表示用文字列） */
  totalDistanceText: string;
  /** 総所要時間（秒） */
  totalDurationSeconds: number;
  /** 総所要時間（表示用文字列） */
  totalDurationText: string;
  /** 最適化されたスポット一覧 */
  spots: {
    order: number;
    name: string;
    type: 'start' | 'waypoint' | 'destination';
    address?: string;
    distanceToNextText?: string;
    durationToNextText?: string;
  }[];
}
