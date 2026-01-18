import { GoogleGenerativeAI, RequestOptions } from '@google/generative-ai';

/**
 * Gemini APIクライアント
 * Google Generative AIを使用したテキスト生成
 */
export class GeminiClient {
  private genAI: GoogleGenerativeAI;
  private model: any;
  private timeout: number;
  private maxRetries: number;

  /**
   * GeminiClientのコンストラクタ
   * @param apiKey Google AI StudioのAPIキー
   */
  constructor(apiKey: string) {
    this.genAI = new GoogleGenerativeAI(apiKey);
    // Using Gemini 1.5 Flash model (faster and more cost-effective)
    // Alternative: 'gemini-1.5-pro' for more advanced capabilities
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
    this.timeout = 30000; // 30秒のタイムアウトを設定（qwen-clientと同じ）
    this.maxRetries = 2; // リトライ回数を設定（qwen-clientと同じ）
  }

  /**
   * テキスト生成
   * @param message ユーザーメッセージ
   * @returns レスポンステキスト
   */
  async chat(message: string): Promise<string> {
    return this.executeWithRetry(async () => {
      try {
        const requestOptions: RequestOptions = {
          timeout: this.timeout,
        };

        const result = await this.model.generateContent(message, requestOptions);
        const response = await result.response;
        return response.text();
      } catch (error: any) {
        console.error('Gemini API detailed error:', {
          message: error.message,
          status: error.status,
          statusText: error.statusText,
          code: error.code,
        });

        // エラーの種類に応じて適切なメッセージを返す
        if (error.status === 400 || error.status === 401) {
          throw new Error('Gemini API: APIキーが無効です。GEMINI_API_KEYを確認してください。');
        } else if (error.status === 429) {
          throw new Error('Gemini API: レート制限に達しました。しばらく待ってから再試行してください。');
        } else if (error.status === 500 || error.status === 503) {
          // サーバーエラーはリトライ対象
          throw new Error('Gemini API: サーバーエラーが発生しました。リトライします。');
        } else if (error.code === 'ECONNABORTED') {
          throw new Error('Gemini API: タイムアウトしました。しばらく待ってから再試行してください。');
        } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
          throw new Error('Gemini API: ネットワーク接続エラー。接続を確認してください。');
        }

        throw new Error(`Gemini API error: ${error.message || error}`);
      }
    });
  }

  /**
   * リトライロジック付きで関数を実行
   * @param fn 実行する非同期関数
   * @returns 関数の実行結果
   */
  private async executeWithRetry<T>(fn: () => Promise<T>): Promise<T> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error: any) {
        lastError = error;

        // リトライ可能なエラーかチェック
        const isRetryable = error.status === 500 || error.status === 503 || error.code === 'ECONNABORTED';

        if (!isRetryable || attempt === this.maxRetries) {
          // リトライ不可能なエラー、または最後の試行
          throw error;
        }

        // 指数バックオフで待機（2^attempt * 1000ms）
        const backoffMs = Math.pow(2, attempt) * 1000;
        console.log(`Gemini API: リトライ ${attempt + 1}/${this.maxRetries} (${backoffMs}ms後)`);
        await new Promise(resolve => setTimeout(resolve, backoffMs));
      }
    }

    throw lastError || new Error('Gemini API: 予期しないエラー');
  }
}
