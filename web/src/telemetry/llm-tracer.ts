/**
 * LLM Tracer Utilities for Manual Instrumentation
 *
 * This module provides utilities for manually instrumenting LLM calls
 * that are not automatically instrumented by OpenLLMetry (e.g., Google Gemini).
 */

import { trace, Span, SpanStatusCode, context, SpanKind } from '@opentelemetry/api';
import { LLM_ATTRIBUTES } from './tracing';

const tracer = trace.getTracer('llm-tracer', '1.0.0');

export interface LLMCallOptions {
  /** The LLM provider (e.g., 'google', 'anthropic', 'qwen') */
  provider: string;
  /** The model name (e.g., 'gemini-2.5-flash-lite', 'claude-3-opus') */
  model: string;
  /** The operation type (e.g., 'chat', 'completion', 'embedding') */
  operation?: string;
  /** Request temperature */
  temperature?: number;
  /** Maximum tokens for response */
  maxTokens?: number;
}

export interface LLMCallResult {
  /** The response content */
  content: string;
  /** Number of prompt/input tokens (if available) */
  promptTokens?: number;
  /** Number of completion/output tokens (if available) */
  completionTokens?: number;
  /** Total tokens (if available) */
  totalTokens?: number;
  /** Additional metadata */
  metadata?: Record<string, string | number | boolean>;
}

/**
 * Trace an LLM call with OpenTelemetry
 *
 * @example
 * ```typescript
 * const result = await traceLLMCall(
 *   { provider: 'google', model: 'gemini-2.5-flash-lite' },
 *   'What is the capital of Japan?',
 *   async (span) => {
 *     const response = await geminiModel.generateContent(prompt);
 *     return {
 *       content: response.text(),
 *       promptTokens: response.usageMetadata?.promptTokenCount,
 *       completionTokens: response.usageMetadata?.candidatesTokenCount,
 *     };
 *   }
 * );
 * ```
 */
export async function traceLLMCall<T extends LLMCallResult>(
  options: LLMCallOptions,
  prompt: string | Array<{ role: string; content: string }>,
  fn: (span: Span) => Promise<T>
): Promise<T> {
  const spanName = `${options.provider}.${options.operation || 'chat'}`;

  return tracer.startActiveSpan(
    spanName,
    {
      kind: SpanKind.CLIENT,
      attributes: {
        [LLM_ATTRIBUTES.LLM_SYSTEM]: options.provider,
        [LLM_ATTRIBUTES.LLM_REQUEST_MODEL]: options.model,
        [LLM_ATTRIBUTES.LLM_OPERATION_NAME]: options.operation || 'chat',
        ...(options.temperature !== undefined && {
          [LLM_ATTRIBUTES.LLM_REQUEST_TEMPERATURE]: options.temperature,
        }),
        ...(options.maxTokens !== undefined && {
          [LLM_ATTRIBUTES.LLM_REQUEST_MAX_TOKENS]: options.maxTokens,
        }),
      },
    },
    async (span) => {
      try {
        // プロンプトを記録
        const promptText =
          typeof prompt === 'string'
            ? prompt
            : prompt.map((m) => `${m.role}: ${m.content}`).join('\n');

        span.setAttribute(LLM_ATTRIBUTES.LLM_PROMPTS, promptText);

        const startTime = Date.now();
        const result = await fn(span);
        const duration = Date.now() - startTime;

        // レスポンスを記録
        span.setAttribute(LLM_ATTRIBUTES.LLM_COMPLETIONS, result.content);
        span.setAttribute(LLM_ATTRIBUTES.LLM_RESPONSE_MODEL, options.model);

        // トークン使用量を記録
        if (result.promptTokens !== undefined) {
          span.setAttribute(LLM_ATTRIBUTES.LLM_USAGE_PROMPT_TOKENS, result.promptTokens);
        }
        if (result.completionTokens !== undefined) {
          span.setAttribute(LLM_ATTRIBUTES.LLM_USAGE_COMPLETION_TOKENS, result.completionTokens);
        }
        if (result.totalTokens !== undefined) {
          span.setAttribute(LLM_ATTRIBUTES.LLM_USAGE_TOTAL_TOKENS, result.totalTokens);
        } else if (result.promptTokens !== undefined && result.completionTokens !== undefined) {
          span.setAttribute(
            LLM_ATTRIBUTES.LLM_USAGE_TOTAL_TOKENS,
            result.promptTokens + result.completionTokens
          );
        }

        // レイテンシを記録
        span.setAttribute('llm.latency_ms', duration);

        // 追加のメタデータを記録
        if (result.metadata) {
          for (const [key, value] of Object.entries(result.metadata)) {
            span.setAttribute(`llm.metadata.${key}`, value);
          }
        }

        span.setStatus({ code: SpanStatusCode.OK });
        return result;
      } catch (error) {
        // エラーを記録
        const errorMessage = error instanceof Error ? error.message : String(error);
        span.setStatus({
          code: SpanStatusCode.ERROR,
          message: errorMessage,
        });
        span.recordException(error instanceof Error ? error : new Error(errorMessage));
        throw error;
      } finally {
        span.end();
      }
    }
  );
}

/**
 * Create a traced wrapper for an LLM client
 *
 * @example
 * ```typescript
 * const tracedGemini = createTracedLLMClient(
 *   geminiClient,
 *   { provider: 'google', model: 'gemini-2.5-flash-lite' }
 * );
 * const result = await tracedGemini.chat('Hello');
 * ```
 */
export function createTracedLLMClient<T extends { chat(message: string): Promise<string> }>(
  client: T,
  options: LLMCallOptions
): T {
  return new Proxy(client, {
    get(target, prop) {
      if (prop === 'chat') {
        return async (message: string): Promise<string> => {
          const result = await traceLLMCall(options, message, async () => {
            const content = await target.chat(message);
            return { content };
          });
          return result.content;
        };
      }
      return Reflect.get(target, prop);
    },
  }) as T;
}

/**
 * Start a custom LLM span for complex operations
 */
export function startLLMSpan(
  name: string,
  options: LLMCallOptions
): { span: Span; end: () => void } {
  const span = tracer.startSpan(name, {
    kind: SpanKind.CLIENT,
    attributes: {
      [LLM_ATTRIBUTES.LLM_SYSTEM]: options.provider,
      [LLM_ATTRIBUTES.LLM_REQUEST_MODEL]: options.model,
      [LLM_ATTRIBUTES.LLM_OPERATION_NAME]: options.operation || 'custom',
    },
  });

  return {
    span,
    end: () => span.end(),
  };
}
