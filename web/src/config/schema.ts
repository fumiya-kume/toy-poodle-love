/**
 * 環境変数のスキーマ定義
 * 型定義とデフォルト値を集約
 */

export type QwenRegion = 'china' | 'international';

export interface ValidatedEnv {
  qwenApiKey: string | undefined;
  geminiApiKey: string | undefined;
  googleMapsApiKey: string | undefined;
  qwenRegion: QwenRegion;
}

export const ENV_DEFAULTS = {
  QWEN_REGION: 'international' as QwenRegion,
} as const;
