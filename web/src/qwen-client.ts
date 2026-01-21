import OpenAI from 'openai';
import { createQwenTrace } from './langfuse-client';

export class QwenClient {
  private client: OpenAI;
  private region: string;

  constructor(apiKey: string, region: 'china' | 'international' = 'international') {
    // Qwen uses OpenAI-compatible API via DashScope
    // International (Singapore/Virginia): dashscope-intl.aliyuncs.com
    // China (Beijing): dashscope.aliyuncs.com
    this.region = region;
    const baseURL = region === 'china'
      ? 'https://dashscope.aliyuncs.com/compatible-mode/v1'
      : 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';

    console.log('Qwen Client initialized:', {
      region,
      baseURL,
      hasApiKey: !!apiKey,
    });

    this.client = new OpenAI({
      apiKey,
      baseURL,
      timeout: 90000, // 90秒のタイムアウト
      maxRetries: 3,  // リトライは3回まで
      fetch: globalThis.fetch, // グローバルfetchを明示的に使用
    });
  }

  async chat(message: string): Promise<string> {
    const modelName = 'qwen-turbo';

    // Langfuseトレースを開始
    const trace = createQwenTrace('qwen-chat', message, {
      model: modelName,
      region: this.region,
    });

    try {
      console.log('Qwen API Request starting:', {
        messageLength: message.length,
        timestamp: new Date().toISOString(),
      });

      const completion = await this.client.chat.completions.create({
        model: modelName,
        messages: [
          {
            role: 'user',
            content: message,
          },
        ],
        temperature: 0.7,
        max_tokens: 2000,
      });

      console.log('Qwen API Response received:', {
        hasContent: !!completion.choices[0]?.message?.content,
        contentLength: completion.choices[0]?.message?.content?.length,
        model: completion.model,
        timestamp: new Date().toISOString(),
      });

      const responseText = completion.choices[0]?.message?.content || 'No response';

      // トレースを終了（成功）
      if (trace) {
        const usage = completion.usage;
        await trace.end(
          responseText,
          usage ? {
            totalTokens: usage.total_tokens,
            promptTokens: usage.prompt_tokens,
            completionTokens: usage.completion_tokens,
          } : undefined
        );
      }

      return responseText;
    } catch (error: any) {
      // 非常に詳細なエラーログ
      console.error('Qwen API Error (詳細ログ):', {
        errorName: error.name,
        errorMessage: error.message,
        errorStatus: error.status,
        errorType: error.type,
        errorCode: error.code,
        errorCause: error.cause,
        errorStack: error.stack?.substring(0, 1000),
        region: this.region,
        timestamp: new Date().toISOString(),
      });

      // エラーメッセージを作成
      let errorMessage: string;

      // OpenAI SDKの特定のエラー
      if (error.status === 401) {
        errorMessage = 'Qwen API: APIキーが無効です。QWEN_API_KEYを確認してください。';
      } else if (error.status === 429) {
        errorMessage = 'Qwen API: レート制限に達しました。しばらく待ってから再試行してください。';
      } else if (error.status === 400) {
        errorMessage = `Qwen API: リクエストが無効です。${error.message}`;
      }
      // ネットワークエラー
      else if (error.code === 'ECONNREFUSED') {
        errorMessage = `Qwen API: 接続拒否エラー。エンドポイント(region=${this.region})への接続が拒否されました。`;
      } else if (error.code === 'ENOTFOUND') {
        errorMessage = `Qwen API: DNSエラー。ホスト名を解決できません(region=${this.region})。`;
      } else if (error.code === 'ETIMEDOUT') {
        errorMessage = 'Qwen API: 接続タイムアウト。ネットワーク接続を確認してください。';
      }
      // OpenAI SDKのエラータイプ
      else if (error.constructor?.name === 'APIConnectionError') {
        errorMessage = `Qwen API: API接続エラー。${error.message}。リージョン設定(${this.region})を確認してください。`;
      } else if (error.constructor?.name === 'APITimeoutError') {
        errorMessage = 'Qwen API: APIタイムアウト。リクエストが90秒以内に完了しませんでした。';
      }
      // "Connection error"のような一般的なエラーの場合、より詳細な情報を追加
      else if (error.message && error.message.toLowerCase().includes('connection')) {
        const details = [
          `Region: ${this.region}`,
          error.cause ? `Cause: ${JSON.stringify(error.cause)}` : null,
          error.code ? `Code: ${error.code}` : null,
        ].filter(Boolean).join(', ');

        errorMessage = `Qwen API: 接続エラー (${error.message}). 詳細: ${details}`;
      }
      // 一般的なエラー
      else if (error.message) {
        errorMessage = `Qwen API: ${error.message}`;
      }
      // 完全に不明なエラー
      else {
        errorMessage = `Qwen API: 予期しないエラーが発生しました。エラー型: ${error.constructor?.name || 'unknown'}, エラー内容: ${JSON.stringify(error)}`;
      }

      // トレースを終了（エラー）
      if (trace) {
        const errorObj = new Error(errorMessage);
        await trace.end('', undefined, errorObj);
      }

      throw new Error(errorMessage);
    }
  }
}
