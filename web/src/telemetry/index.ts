/**
 * Telemetry Module for ARMS LLMOps
 *
 * Re-exports all telemetry utilities for easy import.
 *
 * @example
 * ```typescript
 * import { initARMSTracing, traceLLMCall } from './telemetry';
 *
 * // Initialize at app startup
 * initARMSTracing();
 *
 * // Use traceLLMCall for custom LLM tracing
 * const result = await traceLLMCall(
 *   { provider: 'google', model: 'gemini-2.5-flash-lite' },
 *   prompt,
 *   async () => { ... }
 * );
 * ```
 */

export {
  initARMSTracing,
  isTracingInitialized,
  getTraceloop,
  LLM_ATTRIBUTES,
  type ARMSConfig,
} from './tracing';

export {
  traceLLMCall,
  createTracedLLMClient,
  startLLMSpan,
  type LLMCallOptions,
  type LLMCallResult,
} from './llm-tracer';
