/**
 * ルート自動生成に関する型定義
 */

import { RouteSpot, OutputLanguage, ModelSelection } from './scenario';

/**
 * ルート生成の入力パラメータ
 */
export interface RouteGenerationInput {
  /** スタート地点（例: 東京駅） */
  startPoint: string;
  /** 目的・テーマ（例: 皇居周辺を観光したい） */
  purpose: string;
  /** 生成する地点数（3-8） */
  spotCount: number;
  /** 出力言語（省略時はauto） */
  language?: OutputLanguage;
  /** 使用するモデル */
  model: 'qwen' | 'gemini';
}

/**
 * 生成されたルートの地点
 */
export interface GeneratedRouteSpot extends RouteSpot {
  /** 生成時の補足情報 */
  generatedNote?: string;
}

/**
 * ルート生成の出力
 */
export interface RouteGenerationOutput {
  /** 生成日時 */
  generatedAt: string;
  /** 生成されたルート名 */
  routeName: string;
  /** 生成された地点リスト */
  spots: GeneratedRouteSpot[];
  /** 使用したモデル */
  model: 'qwen' | 'gemini';
  /** 処理時間（ミリ秒） */
  processingTimeMs: number;
}
