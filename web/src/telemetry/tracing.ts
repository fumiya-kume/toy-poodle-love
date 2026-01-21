/**
 * Alibaba Cloud ARMS LLMOps Tracing Module
 *
 * This module initializes OpenTelemetry with OpenLLMetry for LLM observability.
 * It sends traces to Alibaba Cloud ARMS via OTLP HTTP protocol.
 *
 * Environment Variables:
 * - ARMS_ENDPOINT: ARMS OTLP HTTP endpoint (e.g., http://<region>.arms.aliyuncs.com:8090/api/otlp/traces)
 * - ARMS_AUTH_TOKEN: Authentication token for ARMS (optional, depends on region)
 * - OTEL_SERVICE_NAME: Service name for tracing (default: 'taxi-scenario-writer')
 */

import * as Traceloop from '@traceloop/node-server-sdk';
import {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

// Deployment environment attribute (not in stable semantic conventions yet)
const ATTR_DEPLOYMENT_ENVIRONMENT = 'deployment.environment';

// LLM関連のセマンティック属性（OpenLLMetry標準）
export const LLM_ATTRIBUTES = {
  // 入力関連
  LLM_REQUEST_MODEL: 'gen_ai.request.model',
  LLM_REQUEST_MAX_TOKENS: 'gen_ai.request.max_tokens',
  LLM_REQUEST_TEMPERATURE: 'gen_ai.request.temperature',
  LLM_PROMPTS: 'gen_ai.prompt',

  // 出力関連
  LLM_RESPONSE_MODEL: 'gen_ai.response.model',
  LLM_COMPLETIONS: 'gen_ai.completion',
  LLM_USAGE_PROMPT_TOKENS: 'gen_ai.usage.input_tokens',
  LLM_USAGE_COMPLETION_TOKENS: 'gen_ai.usage.output_tokens',
  LLM_USAGE_TOTAL_TOKENS: 'gen_ai.usage.total_tokens',

  // メタデータ
  LLM_SYSTEM: 'gen_ai.system',
  LLM_OPERATION_NAME: 'gen_ai.operation.name',
} as const;

export interface ARMSConfig {
  /** ARMS OTLP HTTP endpoint */
  endpoint?: string;
  /** Authentication token for ARMS */
  authToken?: string;
  /** Service name for tracing */
  serviceName?: string;
  /** Service version */
  serviceVersion?: string;
  /** Environment (e.g., 'production', 'staging', 'development') */
  environment?: string;
  /** Whether to disable tracing (useful for local development) */
  disabled?: boolean;
}

let isInitialized = false;

/**
 * Initialize ARMS LLMOps tracing
 *
 * This function should be called once at application startup, before any LLM calls.
 * It sets up OpenTelemetry with OpenLLMetry instrumentation for automatic LLM tracing.
 */
export function initARMSTracing(config: ARMSConfig = {}): void {
  if (isInitialized) {
    console.log('ARMS tracing already initialized');
    return;
  }

  const {
    endpoint = process.env.ARMS_ENDPOINT,
    authToken = process.env.ARMS_AUTH_TOKEN,
    serviceName = process.env.OTEL_SERVICE_NAME || 'taxi-scenario-writer',
    serviceVersion = process.env.npm_package_version || '1.0.0',
    environment = process.env.NODE_ENV || 'development',
    disabled = process.env.ARMS_TRACING_DISABLED === 'true',
  } = config;

  if (disabled) {
    console.log('ARMS tracing is disabled');
    return;
  }

  if (!endpoint) {
    console.warn(
      'ARMS_ENDPOINT is not set. Tracing will be disabled. ' +
        'Set ARMS_ENDPOINT to enable LLMOps monitoring.'
    );
    return;
  }

  console.log('Initializing ARMS LLMOps tracing:', {
    endpoint: endpoint.replace(/\/\/.*@/, '//***@'), // Hide auth in logs
    serviceName,
    environment,
    hasAuthToken: !!authToken,
  });

  try {
    // ARMS用のOTLP HTTPエクスポーターを作成
    const headers: Record<string, string> = {
      'Content-Type': 'application/x-protobuf',
    };

    // ARMS認証トークンがある場合はヘッダーに追加
    if (authToken) {
      headers['Authentication'] = authToken;
    }

    const traceExporter = new OTLPTraceExporter({
      url: endpoint,
      headers,
    });

    // OpenLLMetryを初期化（OpenAI互換APIを自動計装）
    // 環境変数でリソース属性を設定
    process.env.OTEL_RESOURCE_ATTRIBUTES = [
      `${ATTR_SERVICE_NAME}=${serviceName}`,
      `${ATTR_SERVICE_VERSION}=${serviceVersion}`,
      `${ATTR_DEPLOYMENT_ENVIRONMENT}=${environment}`,
      'service.provider=alibaba-cloud-arms',
      'llm.framework=openllmetry',
    ].join(',');

    Traceloop.initialize({
      appName: serviceName,
      baseUrl: endpoint,
      headers,
      disableBatch: false, // バッチ処理を有効にしてパフォーマンス向上
      exporter: traceExporter,
    });

    isInitialized = true;
    console.log('ARMS LLMOps tracing initialized successfully');
  } catch (error) {
    console.error('Failed to initialize ARMS tracing:', error);
  }
}

/**
 * Check if tracing is initialized
 */
export function isTracingInitialized(): boolean {
  return isInitialized;
}

/**
 * Get the Traceloop SDK instance for custom instrumentation
 */
export function getTraceloop(): typeof Traceloop {
  return Traceloop;
}
