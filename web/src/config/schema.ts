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
  // Langfuse LLMOps設定
  langfuseEnabled: boolean;
  langfuseSecretKey: string | undefined;
  langfusePublicKey: string | undefined;
  langfuseBaseUrl: string | undefined;
}

export const ENV_DEFAULTS = {
  QWEN_REGION: 'international' as QwenRegion,
  LANGFUSE_ENABLED: true as boolean,
  LANGFUSE_BASE_URL: 'https://cloud.langfuse.com' as string,
} as const;
