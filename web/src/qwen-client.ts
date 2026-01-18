/**
 * Qwen APIクライアント（fetch直接実装）
 * テキスト専用とVision-Languageモデルの両方をサポート
 */
export class QwenClient {
  private apiKey: string;
  private baseURL: string;
  private region: 'china' | 'international';
  private timeout: number;
  private maxRetries: number;

  /**
   * QwenClientのコンストラクタ
   * @param apiKey Alibaba Cloud DashScopeのAPIキー
   * @param region リージョン選択（'china': 中国、'international': 国際）
   */
  constructor(apiKey: string, region: 'china' | 'international' = 'international') {
    if (!apiKey) {
      throw new Error('Qwen API: APIキーが設定されていません。QWEN_API_KEYを確認してください。');
    }

    // Qwen uses OpenAI-compatible API via DashScope
    // International (Singapore/Virginia): dashscope-intl.aliyuncs.com
    // China (Beijing): dashscope.aliyuncs.com
    this.baseURL = region === 'china'
      ? 'https://dashscope.aliyuncs.com/compatible-mode/v1'
      : 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';

    this.apiKey = apiKey;
    this.timeout = 60000; // 60秒のタイムアウトを設定
    this.maxRetries = 3; // リトライ回数を3回に設定
    this.region = region;

    console.log(`[QwenClient] 初期化: region=${region}, baseURL=${this.baseURL}, timeout=${this.timeout}ms, apiKey=${apiKey.substring(0, 8)}...`);
  }

  /**
   * テキスト専用モデルでチャット
   * @param message ユーザーメッセージ
   * @returns レスポンステキスト
   */
  async chat(message: string): Promise<string> {
    return this.executeWithRetry(async () => {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      try {
        console.log(`[QwenClient] API呼び出し開始: ${this.baseURL}/chat/completions`);

        const response = await fetch(`${this.baseURL}/chat/completions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`,
          },
          body: JSON.stringify({
            model: 'qwen-turbo',
            messages: [
              {
                role: 'user',
                content: message,
              },
            ],
            temperature: 0.7,
            max_tokens: 2000,
          }),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        console.log(`[QwenClient] レスポンス受信: status=${response.status}, ok=${response.ok}`);

        if (!response.ok) {
          const errorText = await response.text();
          console.error(`[QwenClient] APIエラーレスポンス: ${errorText}`);
          throw new Error(`HTTP ${response.status}: ${errorText}`);
        }

        const data = await response.json();
        const content = data.choices?.[0]?.message?.content || 'No response';
        console.log(`[QwenClient] 成功: レスポンス長=${content.length}文字`);
        return content;
      } catch (error: any) {
        clearTimeout(timeoutId);

        console.error('[QwenClient] chat() エラー:', {
          message: error.message,
          name: error.name,
          cause: error.cause,
        });

        // エラーの種類に応じて適切なメッセージを返す
        if (error.name === 'AbortError') {
          throw new Error(`Qwen API: タイムアウトしました（${this.timeout / 1000}秒）。リージョン: ${this.region}`);
        } else if (error.message?.includes('HTTP 401')) {
          throw new Error('Qwen API: APIキーが無効です。QWEN_API_KEYを確認してください。');
        } else if (error.message?.includes('HTTP 429')) {
          throw new Error('Qwen API: レート制限に達しました。しばらく待ってから再試行してください。');
        } else if (error.message?.includes('HTTP 500') || error.message?.includes('HTTP 503')) {
          throw new Error('Qwen API: サーバーエラーが発生しました。しばらく待ってから再試行してください。');
        } else if (error.message?.includes('fetch failed') || error.message?.includes('Failed to fetch')) {
          throw new Error(`Qwen API: ネットワーク接続エラー。リージョン: ${this.region}, URL: ${this.baseURL}`);
        }

        throw error;
      }
    });
  }

  /**
   * Vision-Language モデルで画像を含むチャット
   * @param message テキストメッセージ
   * @param imageUrl 画像URL (base64エンコードまたはURL)
   * @returns レスポンステキスト
   */
  async chatWithImage(message: string, imageUrl: string): Promise<string> {
    return this.executeWithRetry(async () => {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      try {
        console.log(`[QwenClient] VL API呼び出し開始: ${this.baseURL}/chat/completions`);

        const response = await fetch(`${this.baseURL}/chat/completions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`,
          },
          body: JSON.stringify({
            model: 'qwen3-vl-flash',
            messages: [
              {
                role: 'user',
                content: [
                  {
                    type: 'text',
                    text: message,
                  },
                  {
                    type: 'image_url',
                    image_url: {
                      url: imageUrl,
                    },
                  },
                ],
              },
            ],
            temperature: 0.7,
            max_tokens: 2000,
          }),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        console.log(`[QwenClient] VL レスポンス受信: status=${response.status}, ok=${response.ok}`);

        if (!response.ok) {
          const errorText = await response.text();
          console.error(`[QwenClient] VL APIエラーレスポンス: ${errorText}`);
          throw new Error(`HTTP ${response.status}: ${errorText}`);
        }

        const data = await response.json();
        const content = data.choices?.[0]?.message?.content || 'No response';
        console.log(`[QwenClient] VL 成功: レスポンス長=${content.length}文字`);
        return content;
      } catch (error: any) {
        clearTimeout(timeoutId);

        console.error('[QwenClient] chatWithImage() エラー:', {
          message: error.message,
          name: error.name,
          cause: error.cause,
        });

        // エラーの種類に応じて適切なメッセージを返す
        if (error.name === 'AbortError') {
          throw new Error(`Qwen VL API: タイムアウトしました（${this.timeout / 1000}秒）。リージョン: ${this.region}`);
        } else if (error.message?.includes('HTTP 401')) {
          throw new Error('Qwen VL API: APIキーが無効です。QWEN_API_KEYを確認してください。');
        } else if (error.message?.includes('HTTP 429')) {
          throw new Error('Qwen VL API: レート制限に達しました。しばらく待ってから再試行してください。');
        } else if (error.message?.includes('HTTP 500') || error.message?.includes('HTTP 503')) {
          throw new Error('Qwen VL API: サーバーエラーが発生しました。しばらく待ってから再試行してください。');
        } else if (error.message?.includes('fetch failed') || error.message?.includes('Failed to fetch')) {
          throw new Error(`Qwen VL API: ネットワーク接続エラー。リージョン: ${this.region}, URL: ${this.baseURL}`);
        }

        throw error;
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
        if (attempt > 0) {
          console.log(`[QwenClient] リトライ試行 ${attempt}/${this.maxRetries}`);
        }
        return await fn();
      } catch (error: any) {
        lastError = error;

        // より詳細なエラーログ
        console.error(`[QwenClient] エラー発生 (試行 ${attempt + 1}/${this.maxRetries + 1}):`, {
          message: error.message,
          name: error.name,
          cause: error.cause,
          stack: error.stack?.substring(0, 200),
        });

        // リトライ可能なエラーかチェック
        const isRetryable =
          error.name === 'AbortError' ||
          error.message?.includes('HTTP 500') ||
          error.message?.includes('HTTP 502') ||
          error.message?.includes('HTTP 503') ||
          error.message?.includes('timeout') ||
          error.message?.includes('fetch failed') ||
          error.message?.includes('Failed to fetch') ||
          error.message?.includes('network') ||
          error.message?.includes('Connection error');

        console.log(`[QwenClient] リトライ可能: ${isRetryable}, 最後の試行: ${attempt === this.maxRetries}`);

        if (!isRetryable || attempt === this.maxRetries) {
          // リトライ不可能なエラー、または最後の試行
          console.error(`[QwenClient] リトライ終了: region=${this.region}, baseURL=${this.baseURL}`);
          throw error;
        }

        // 指数バックオフで待機（2^attempt * 1000ms、最大8秒）
        const backoffMs = Math.min(Math.pow(2, attempt) * 1000, 8000);
        console.log(`[QwenClient] ${backoffMs}ms待機後にリトライします...`);
        await new Promise(resolve => setTimeout(resolve, backoffMs));
      }
    }

    throw lastError || new Error('Qwen API: 予期しないエラー');
  }
}
