/**
 * APIリクエスト/レスポンスの型定義
 */

import { RouteInput, ScenarioOutput, ModelSelection, ScenarioIntegrationInput, ScenarioIntegrationOutput } from './scenario';
import { RouteGenerationInput, RouteGenerationOutput } from './route';

/**
 * シナリオ生成APIリクエスト
 */
export interface ScenarioRequest {
  /** ルート情報 */
  route: RouteInput;
  /** 使用するモデル */
  models?: ModelSelection;
  /** 画像生成プロンプトを含めるか */
  includeImagePrompt?: boolean;
}

/**
 * シナリオ生成APIレスポンス
 */
export interface ScenarioResponse {
  /** 成功フラグ */
  success: boolean;
  /** シナリオデータ */
  data?: ScenarioOutput;
  /** エラーメッセージ */
  error?: string;
}

/**
 * 単一地点シナリオ生成リクエスト
 */
export interface SpotScenarioRequest {
  /** ルート名（コンテキスト用） */
  routeName: string;
  /** 地点名 */
  spotName: string;
  /** 地点の説明 */
  description?: string;
  /** 観光ポイント */
  point?: string;
  /** 使用するモデル */
  models?: ModelSelection;
  /** 画像生成プロンプトを含めるか */
  includeImagePrompt?: boolean;
}

/**
 * 単一地点シナリオ生成レスポンス
 */
export interface SpotScenarioResponse {
  /** 成功フラグ */
  success: boolean;
  /** 生成されたセリフ */
  scenario?: {
    qwen?: string;
    gemini?: string;
  };
  /** エラーメッセージ */
  error?: string;
}

/**
 * シナリオ統合APIリクエスト
 */
export interface ScenarioIntegrationRequest {
  /** 統合入力データ */
  integration: ScenarioIntegrationInput;
}

/**
 * シナリオ統合APIレスポンス
 */
export interface ScenarioIntegrationResponse {
  /** 成功フラグ */
  success: boolean;
  /** 統合されたシナリオ */
  data?: ScenarioIntegrationOutput;
  /** エラーメッセージ */
  error?: string;
}

/**
 * ルート自動生成APIリクエスト
 */
export interface RouteGenerationRequest {
  /** ルート生成入力 */
  input: RouteGenerationInput;
}

/**
 * ルート自動生成APIレスポンス
 */
export interface RouteGenerationResponse {
  /** 成功フラグ */
  success: boolean;
  /** 生成されたルート */
  data?: RouteGenerationOutput;
  /** エラーメッセージ */
  error?: string;
}
