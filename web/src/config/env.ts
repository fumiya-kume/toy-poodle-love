/**
 * 中央集権的な環境変数管理モジュール
 *
 * 設計ポイント:
 * - シングルトンパターンで一度だけ初期化
 * - Next.jsのサーバーサイドでは自動読み込みを利用
 * - CLIモードでは明示的なdotenv読み込み
 */

import * as dotenv from 'dotenv';
import { ValidatedEnv, QwenRegion, ENV_DEFAULTS } from './schema';

let isInitialized = false;
let cachedEnv: ValidatedEnv | null = null;

/**
 * dotenvの初期化（CLIモード用）
 * Next.jsでは呼ぶ必要なし
 */
export function initializeDotenv(): void {
  if (isInitialized) return;

  // Next.js環境かどうかを判定
  const isNextJs = typeof process.env.NEXT_RUNTIME !== 'undefined';

  if (!isNextJs) {
    dotenv.config();
  }

  isInitialized = true;
}

/**
 * 環境変数のバリデーションと変換
 */
function validateAndTransform(): ValidatedEnv {
  const qwenRegionRaw = process.env.QWEN_REGION || ENV_DEFAULTS.QWEN_REGION;

  let qwenRegion: QwenRegion = 'international';
  if (qwenRegionRaw === 'china' || qwenRegionRaw === 'international') {
    qwenRegion = qwenRegionRaw;
  } else if (qwenRegionRaw) {
    console.warn(
      `Invalid QWEN_REGION value: "${qwenRegionRaw}". Using default: "international"`
    );
  }

  return {
    qwenApiKey: process.env.QWEN_API_KEY || undefined,
    geminiApiKey: process.env.GEMINI_API_KEY || undefined,
    googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || undefined,
    qwenRegion,
  };
}

/**
 * 環境変数を取得（キャッシュ付き）
 */
export function getEnv(): ValidatedEnv {
  if (cachedEnv) return cachedEnv;

  initializeDotenv();
  cachedEnv = validateAndTransform();
  return cachedEnv;
}

export function hasQwenApiKey(): boolean {
  return !!getEnv().qwenApiKey;
}

export function hasGeminiApiKey(): boolean {
  return !!getEnv().geminiApiKey;
}

export function hasGoogleMapsApiKey(): boolean {
  return !!getEnv().googleMapsApiKey;
}

/**
 * 必須の環境変数が設定されているか確認（起動時バリデーション用）
 * @throws Error if required keys are missing
 */
export function validateRequiredKeys(
  keys: Array<'qwen' | 'gemini' | 'googleMaps'>
): void {
  const env = getEnv();
  const missing: string[] = [];

  for (const key of keys) {
    switch (key) {
      case 'qwen':
        if (!env.qwenApiKey) missing.push('QWEN_API_KEY');
        break;
      case 'gemini':
        if (!env.geminiApiKey) missing.push('GEMINI_API_KEY');
        break;
      case 'googleMaps':
        if (!env.googleMapsApiKey) missing.push('GOOGLE_MAPS_API_KEY');
        break;
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}`
    );
  }
}

/**
 * キャッシュをクリア（テスト用）
 */
export function clearEnvCache(): void {
  cachedEnv = null;
  isInitialized = false;
}
