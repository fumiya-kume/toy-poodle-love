/**
 * Langfuse LLMOps クライアント
 *
 * Qwen/Gemini APIのトレーシング、コスト追跡、レイテンシ計測を提供
 *
 * 使用方法:
 * - Qwen: observeOpenAI()でOpenAIクライアントをラップ
 * - Gemini: createGeneration()で手動トレース
 */

import { Langfuse } from 'langfuse';
import { observeOpenAI } from 'langfuse';
import OpenAI from 'openai';
import { getEnv, hasLangfuseKeys } from './config';

let langfuseInstance: Langfuse | null = null;

/**
 * Langfuseクライアントを取得（シングルトン）
 * 環境変数が設定されていない場合はnullを返す
 */
export function getLangfuse(): Langfuse | null {
  if (langfuseInstance) return langfuseInstance;

  if (!hasLangfuseKeys()) {
    console.log('[Langfuse] Keys not configured, tracing disabled');
    return null;
  }

  const env = getEnv();

  langfuseInstance = new Langfuse({
    secretKey: env.langfuseSecretKey!,
    publicKey: env.langfusePublicKey!,
    baseUrl: env.langfuseBaseUrl,
  });

  console.log('[Langfuse] Client initialized:', {
    baseUrl: env.langfuseBaseUrl,
    hasSecretKey: !!env.langfuseSecretKey,
    hasPublicKey: !!env.langfusePublicKey,
  });

  return langfuseInstance;
}

/**
 * LangfuseでラップされたOpenAIクライアントを作成
 * Qwen APIはOpenAI互換なのでこれを使用
 *
 * @param openaiClient - ラップするOpenAIクライアント
 * @param options - トレースオプション
 * @returns ラップされたOpenAIクライアント（Langfuse未設定時は元のクライアント）
 */
export function wrapOpenAIWithLangfuse(
  openaiClient: OpenAI,
  options?: {
    generationName?: string;
    tags?: string[];
    metadata?: Record<string, unknown>;
  }
): OpenAI {
  const langfuse = getLangfuse();

  if (!langfuse) {
    return openaiClient;
  }

  return observeOpenAI(openaiClient, {
    generationName: options?.generationName || 'qwen-chat',
    tags: options?.tags || ['qwen'],
    metadata: options?.metadata,
  });
}

/**
 * Gemini API呼び出し用の手動トレースを作成
 *
 * @param name - トレース名
 * @param input - 入力メッセージ
 * @param metadata - 追加メタデータ
 * @returns トレースオブジェクト（終了時にend()を呼ぶ）
 */
export function createGeminiTrace(
  name: string,
  input: string,
  metadata?: Record<string, unknown>
): {
  traceId: string;
  generationId: string;
  end: (output: string, error?: Error) => Promise<void>;
} | null {
  const langfuse = getLangfuse();

  if (!langfuse) {
    return null;
  }

  const trace = langfuse.trace({
    name,
    input,
    tags: ['gemini'],
    metadata,
  });

  const generation = trace.generation({
    name: 'gemini-chat',
    model: 'gemini-2.5-flash-lite',
    input,
    metadata,
  });

  return {
    traceId: trace.id,
    generationId: generation.id,
    end: async (output: string, error?: Error) => {
      generation.end({
        output,
        level: error ? 'ERROR' : 'DEFAULT',
        statusMessage: error?.message,
      });

      trace.update({
        output,
      });

      // バックグラウンドで送信
      await langfuse.flushAsync();
    },
  };
}

/**
 * シナリオ生成などの複合トレースを作成
 *
 * @param name - トレース名
 * @param metadata - メタデータ（ルート名、スポット数など）
 * @returns トレースオブジェクト
 */
export function createScenarioTrace(
  name: string,
  metadata?: Record<string, unknown>
): {
  trace: ReturnType<Langfuse['trace']>;
  addSpan: (spanName: string, input: unknown) => {
    end: (output: unknown) => void;
  };
  end: (output?: unknown) => Promise<void>;
} | null {
  const langfuse = getLangfuse();

  if (!langfuse) {
    return null;
  }

  const trace = langfuse.trace({
    name,
    tags: ['scenario'],
    metadata,
  });

  return {
    trace,
    addSpan: (spanName: string, input: unknown) => {
      const span = trace.span({
        name: spanName,
        input,
      });

      return {
        end: (output: unknown) => {
          span.end({ output });
        },
      };
    },
    end: async (output?: unknown) => {
      trace.update({ output });
      await langfuse.flushAsync();
    },
  };
}

/**
 * Langfuseクライアントをシャットダウン
 * アプリケーション終了時に呼び出し
 */
export async function shutdownLangfuse(): Promise<void> {
  if (langfuseInstance) {
    await langfuseInstance.shutdownAsync();
    langfuseInstance = null;
    console.log('[Langfuse] Client shutdown complete');
  }
}

/**
 * Langfuseが有効かどうかを確認
 */
export function isLangfuseEnabled(): boolean {
  return hasLangfuseKeys();
}
