import OpenAI from 'openai';
import { wrapOpenAIWithLangfuse, isLangfuseEnabled } from './langfuse-client';

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
      langfuseEnabled: isLangfuseEnabled(),
    });

    const rawClient = new OpenAI({
      apiKey,
      baseURL,
      timeout: 90000, // 90秒のタイムアウト
      maxRetries: 3,  // リトライは3回まで
      fetch: globalThis.fetch, // グローバルfetchを明示的に使用
    });

    // LangfuseでラップしてLLMOpsトレーシングを有効化
    this.client = wrapOpenAIWithLangfuse(rawClient, {
      generationName: 'qwen-chat',
      tags: ['qwen', region],
      metadata: { region, baseURL },
    });
  }

  async chat(message: string): Promise<string> {
    try {
      console.log('Qwen API Request starting:', {
        messageLength: message.length,
        timestamp: new Date().toISOString(),
      });

      const completion = await this.client.chat.completions.create({
        model: 'qwen-turbo',
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

      return completion.choices[0]?.message?.content || 'No response';
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

      // OpenAI SDKの特定のエラー
      if (error.status === 401) {
        throw new Error('Qwen API: APIキーが無効です。QWEN_API_KEYを確認してください。');
      }

      if (error.status === 429) {
        throw new Error('Qwen API: レート制限に達しました。しばらく待ってから再試行してください。');
      }

      if (error.status === 400) {
        throw new Error(`Qwen API: リクエストが無効です。${error.message}`);
      }

      // ネットワークエラー
      if (error.code === 'ECONNREFUSED') {
        throw new Error(`Qwen API: 接続拒否エラー。エンドポイント(region=${this.region})への接続が拒否されました。`);
      }

      if (error.code === 'ENOTFOUND') {
        throw new Error(`Qwen API: DNSエラー。ホスト名を解決できません(region=${this.region})。`);
      }

      if (error.code === 'ETIMEDOUT') {
        throw new Error('Qwen API: 接続タイムアウト。ネットワーク接続を確認してください。');
      }

      // OpenAI SDKのエラータイプ
      if (error.constructor?.name === 'APIConnectionError') {
        throw new Error(`Qwen API: API接続エラー。${error.message}。リージョン設定(${this.region})を確認してください。`);
      }

      if (error.constructor?.name === 'APITimeoutError') {
        throw new Error('Qwen API: APIタイムアウト。リクエストが90秒以内に完了しませんでした。');
      }

      // "Connection error"のような一般的なエラーの場合、より詳細な情報を追加
      if (error.message && error.message.toLowerCase().includes('connection')) {
        const details = [
          `Region: ${this.region}`,
          error.cause ? `Cause: ${JSON.stringify(error.cause)}` : null,
          error.code ? `Code: ${error.code}` : null,
        ].filter(Boolean).join(', ');

        throw new Error(`Qwen API: 接続エラー (${error.message}). 詳細: ${details}`);
      }

      // 一般的なエラー
      if (error.message) {
        throw new Error(`Qwen API: ${error.message}`);
      }

      // 完全に不明なエラー
      throw new Error(`Qwen API: 予期しないエラーが発生しました。エラー型: ${error.constructor?.name || 'unknown'}, エラー内容: ${JSON.stringify(error)}`);
    }
  }
}
