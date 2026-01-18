import { GoogleGenerativeAI, RequestOptions } from '@google/generative-ai';

export class GeminiClient {
  private genAI: GoogleGenerativeAI;
  private model: any;
  private requestOptions: RequestOptions;

  constructor(apiKey: string) {
    console.log('Gemini Client initialized:', {
      hasApiKey: !!apiKey,
    });

    this.genAI = new GoogleGenerativeAI(apiKey);
    // Using Gemini 1.5 Flash model (faster and more cost-effective)
    // Alternative: 'gemini-1.5-pro' for more advanced capabilities
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

    // タイムアウトとリトライの設定
    this.requestOptions = {
      timeout: 90000, // 90秒のタイムアウト
    };
  }

  async chat(message: string): Promise<string> {
    let lastError: any = null;
    const maxRetries = 3;

    // リトライループ
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        console.log('Gemini API Request starting:', {
          messageLength: message.length,
          attempt,
          maxRetries,
          timestamp: new Date().toISOString(),
        });

        const result = await this.model.generateContent(message, this.requestOptions);
        const response = await result.response;
        const text = response.text();

        console.log('Gemini API Response received:', {
          hasContent: !!text,
          contentLength: text?.length,
          attempt,
          timestamp: new Date().toISOString(),
        });

        return text;
      } catch (error: any) {
        lastError = error;

        // 非常に詳細なエラーログ
        console.error('Gemini API Error (詳細ログ):', {
          errorName: error.name,
          errorMessage: error.message,
          errorStatus: error.status,
          errorStatusText: error.statusText,
          errorCode: error.code,
          errorCause: error.cause,
          errorStack: error.stack?.substring(0, 1000),
          attempt,
          maxRetries,
          timestamp: new Date().toISOString(),
        });

        // リトライ可能なエラーかチェック
        const isRetryable = this.isRetryableError(error);

        if (attempt < maxRetries && isRetryable) {
          const waitTime = Math.min(1000 * Math.pow(2, attempt - 1), 10000); // 指数バックオフ(最大10秒)
          console.log(`Gemini API: リトライ ${attempt}/${maxRetries}を${waitTime}ms後に実行...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
          continue;
        }

        // 最後の試行、またはリトライ不可能なエラーの場合は抜ける
        break;
      }
    }

    // すべてのリトライが失敗した場合
    throw this.formatError(lastError);
  }

  private isRetryableError(error: any): boolean {
    // 429 (レート制限)、503 (サービス利用不可)、ネットワークエラーはリトライ可能
    if (error.status === 429 || error.status === 503) {
      return true;
    }

    // タイムアウトエラーもリトライ可能
    if (error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) {
      return true;
    }

    // ネットワークエラーもリトライ可能
    if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
      return true;
    }

    return false;
  }

  private formatError(error: any): Error {
    // Google AI SDKの特定のエラー
    if (error.status === 400) {
      throw new Error(`Gemini API: リクエストが無効です。${error.message || error.statusText || ''}`);
    }

    if (error.status === 401 || error.status === 403) {
      throw new Error('Gemini API: APIキーが無効です。GEMINI_API_KEYを確認してください。');
    }

    if (error.status === 429) {
      throw new Error('Gemini API: レート制限に達しました。しばらく待ってから再試行してください。');
    }

    if (error.status === 500) {
      throw new Error('Gemini API: サーバーエラーが発生しました。しばらく待ってから再試行してください。');
    }

    if (error.status === 503) {
      throw new Error('Gemini API: サービスが一時的に利用できません。しばらく待ってから再試行してください。');
    }

    // ネットワークエラー
    if (error.code === 'ECONNREFUSED') {
      throw new Error('Gemini API: 接続拒否エラー。Gemini APIへの接続が拒否されました。');
    }

    if (error.code === 'ENOTFOUND') {
      throw new Error('Gemini API: DNSエラー。ホスト名を解決できません。');
    }

    if (error.code === 'ETIMEDOUT') {
      throw new Error('Gemini API: 接続タイムアウト。ネットワーク接続を確認してください。');
    }

    // タイムアウトエラー
    if (error.message && error.message.toLowerCase().includes('timeout')) {
      throw new Error('Gemini API: APIタイムアウト。リクエストが90秒以内に完了しませんでした。');
    }

    // 一般的なエラー
    if (error.message) {
      throw new Error(`Gemini API: ${error.message}`);
    }

    // 完全に不明なエラー
    throw new Error(`Gemini API: 予期しないエラーが発生しました。エラー型: ${error.constructor?.name || 'unknown'}, エラー内容: ${JSON.stringify(error)}`);
  }
}
