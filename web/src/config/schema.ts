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
  // ARMS LLMOps設定
  armsEndpoint: string | undefined;
  armsAuthToken: string | undefined;
  armsTracingDisabled: boolean;
  otelServiceName: string;
}

export const ENV_DEFAULTS = {
  QWEN_REGION: 'international' as QwenRegion,
  OTEL_SERVICE_NAME: 'taxi-scenario-writer',
  ARMS_TRACING_DISABLED: false,
} as const;
