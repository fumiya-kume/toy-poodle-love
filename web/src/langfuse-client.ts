/**
 * Langfuse LLMOps クライアント
 */

import { Langfuse } from 'langfuse';
import type OpenAI from 'openai';
import { getEnv, isLangfuseEnabled } from './config';

let langfuseInstance: Langfuse | null = null;

/**
 * Langfuseクライアントを取得（シングルトン）
 */
export function getLangfuse(): Langfuse | null {
  // 既にインスタンスが作成されている場合はそれを返す
  if (langfuseInstance) {
    return langfuseInstance;
  }

  // Langfuseが有効でない場合はnullを返す
  if (!isLangfuseEnabled()) {
    return null;
  }

  const env = getEnv();

  // Langfuseクライアントを初期化
  langfuseInstance = new Langfuse({
    secretKey: env.langfuseSecretKey!,
    publicKey: env.langfusePublicKey!,
    baseUrl: env.langfuseBaseUrl,
  });

  console.log('[Langfuse] Client initialized:', {
    baseUrl: env.langfuseBaseUrl,
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
  // observeOpenAIは接続エラーを引き起こすため使用しない
  // 代わりにQwenClientで手動トレーシングを実装
  console.log('[Langfuse] Using manual tracing instead of observeOpenAI');
  return openaiClient;
}

/**
 * Qwen API呼び出し用の手動トレースを作成
 *
 * @param name - トレース名
 * @param input - 入力メッセージ
 * @param metadata - 追加メタデータ
 * @returns トレースオブジェクト（終了時にend()を呼ぶ）
 */
export function createQwenTrace(
  name: string,
  input: string,
  metadata?: Record<string, unknown>
): {
  traceId: string;
  generationId: string;
  end: (output: string, usage?: { totalTokens?: number; promptTokens?: number; completionTokens?: number }, error?: Error) => Promise<void>;
} | null {
  const langfuse = getLangfuse();

  if (!langfuse) {
    return null;
  }

  const trace = langfuse.trace({
    name,
    input,
    tags: ['qwen'],
    metadata,
  });

  const generation = trace.generation({
    name: 'qwen-chat',
    model: metadata?.model as string || 'qwen-turbo',
    input,
    metadata,
  });

  return {
    traceId: trace.id,
    generationId: generation.id,
    end: async (output: string, usage?: { totalTokens?: number; promptTokens?: number; completionTokens?: number }, error?: Error) => {
      generation.end({
        output,
        usage: usage ? {
          total: usage.totalTokens,
          input: usage.promptTokens,
          output: usage.completionTokens,
        } : undefined,
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
 * パイプライン処理などの複合トレースを作成
 *
 * @param name - トレース名
 * @param metadata - メタデータ（リクエスト情報など）
 * @returns トレースオブジェクト
 */
export function createPipelineTrace(
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
    tags: ['pipeline'],
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
