/**
 * E2E Place-Route Optimization パイプラインに関する型定義
 */

import type { GeocodedPlace, OptimizedWaypoint, RouteLeg } from './place-route';
import type { RouteGenerationOutput, GeneratedRouteSpot } from './route';

/**
 * パイプラインリクエスト（入力パラメータ）
 */
export interface PipelineRequest {
  /** スタート地点（例: 東京駅） */
  startPoint: string;
  /** 目的・テーマ（例: 皇居周辺を観光したい） */
  purpose: string;
  /** 生成する地点数（3-8） */
  spotCount: number;
  /** 使用するモデル */
  model: 'qwen' | 'gemini';
}

/**
 * パイプラインの各ステップの状態
 */
export type PipelineStepStatus = 'pending' | 'in_progress' | 'completed' | 'failed';

/**
 * AIルート生成ステップの結果
 */
export interface RouteGenerationStepResult {
  status: PipelineStepStatus;
  /** 生成されたルート名 */
  routeName?: string;
  /** 生成されたスポットリスト */
  spots?: GeneratedRouteSpot[];
  /** 処理時間（ミリ秒） */
  processingTimeMs?: number;
  /** エラーメッセージ */
  error?: string;
}

/**
 * ジオコーディングステップの結果
 */
export interface GeocodingStepResult {
  status: PipelineStepStatus;
  /** ジオコーディングされた場所リスト */
  places?: GeocodedPlace[];
  /** ジオコーディングに失敗した地点名 */
  failedSpots?: string[];
  /** 処理時間（ミリ秒） */
  processingTimeMs?: number;
  /** エラーメッセージ */
  error?: string;
}

/**
 * ルート最適化ステップの結果
 */
export interface RouteOptimizationStepResult {
  status: PipelineStepStatus;
  /** 最適化された順序のウェイポイント */
  orderedWaypoints?: OptimizedWaypoint[];
  /** 各区間の詳細 */
  legs?: RouteLeg[];
  /** 総距離（メートル） */
  totalDistanceMeters?: number;
  /** 総所要時間（秒） */
  totalDurationSeconds?: number;
  /** 処理時間（ミリ秒） */
  processingTimeMs?: number;
  /** エラーメッセージ */
  error?: string;
}

/**
 * パイプラインレスポンス（出力）
 */
export interface PipelineResponse {
  /** 処理が成功したか */
  success: boolean;
  /** リクエストパラメータ（参照用） */
  request: PipelineRequest;
  /** ステップ1: AIルート生成の結果 */
  routeGeneration: RouteGenerationStepResult;
  /** ステップ2: ジオコーディングの結果 */
  geocoding: GeocodingStepResult;
  /** ステップ3: ルート最適化の結果 */
  routeOptimization: RouteOptimizationStepResult;
  /** パイプライン全体の処理時間（ミリ秒） */
  totalProcessingTimeMs: number;
  /** 全体エラーメッセージ */
  error?: string;
}
