import OpenAI from 'openai';

/**
 * Qwen APIクライアント（OpenAI互換）
 * テキスト専用とVision-Languageモデルの両方をサポート
 */
export class QwenClient {
  private client: OpenAI;
  private region: 'china' | 'international';

  /**
   * QwenClientのコンストラクタ
   * @param apiKey Alibaba Cloud DashScopeのAPIキー
   * @param region リージョン選択（'china': 中国、'international': 国際）
   */
  constructor(apiKey: string, region: 'china' | 'international' = 'international') {
    // Qwen uses OpenAI-compatible API via DashScope
    // International (Singapore/Virginia): dashscope-intl.aliyuncs.com
    // China (Beijing): dashscope.aliyuncs.com
    const baseURL = region === 'china'
      ? 'https://dashscope.aliyuncs.com/compatible-mode/v1'
      : 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';

    this.client = new OpenAI({
      apiKey: apiKey,
      baseURL: baseURL,
      timeout: 30000, // 30秒のタイムアウトを設定
      maxRetries: 2, // リトライ回数を設定
    });
    this.region = region;
  }

  /**
   * テキスト専用モデルでチャット
   * @param message ユーザーメッセージ
   * @returns レスポンステキスト
   */
  async chat(message: string): Promise<string> {
    try {
      const response = await this.client.chat.completions.create({
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

      return response.choices[0]?.message?.content || 'No response';
    } catch (error: any) {
      console.error('Qwen API detailed error:', {
        message: error.message,
        status: error.status,
        type: error.type,
        code: error.code,
        cause: error.cause,
      });

      // エラーの種類に応じて適切なメッセージを返す
      if (error.status === 401) {
        throw new Error('Qwen API: APIキーが無効です。QWEN_API_KEYを確認してください。');
      } else if (error.status === 429) {
        throw new Error('Qwen API: レート制限に達しました。しばらく待ってから再試行してください。');
      } else if (error.status === 500 || error.status === 503) {
        throw new Error('Qwen API: サーバーエラーが発生しました。しばらく待ってから再試行してください。');
      } else if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
        throw new Error(`Qwen API: タイムアウトしました（30秒）。リージョン設定(QWEN_REGION=${this.region})を確認するか、しばらく待ってから再試行してください。`);
      } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND' || error.message?.includes('Connection error')) {
        throw new Error(`Qwen API: ネットワーク接続エラー。リージョン設定(QWEN_REGION=${this.region})とインターネット接続を確認してください。`);
      } else if (error.code === 'ETIMEDOUT' || error.code === 'ESOCKETTIMEDOUT') {
        throw new Error('Qwen API: 接続タイムアウト。ネットワーク環境を確認してください。');
      }

      // より詳細なエラーメッセージを提供
      const errorDetails = error.message || JSON.stringify(error);
      throw new Error(`Qwen API error: ${errorDetails}. リージョン: ${this.region}`);
    }
  }

  /**
   * Vision-Language モデルで画像を含むチャット
   * @param message テキストメッセージ
   * @param imageUrl 画像URL (base64エンコードまたはURL)
   * @returns レスポンステキスト
   */
  async chatWithImage(message: string, imageUrl: string): Promise<string> {
    try {
      const response = await this.client.chat.completions.create({
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
      });

      return response.choices[0]?.message?.content || 'No response';
    } catch (error: any) {
      console.error('Qwen VL API detailed error:', {
        message: error.message,
        status: error.status,
        type: error.type,
        code: error.code,
        cause: error.cause,
      });

      // エラーの種類に応じて適切なメッセージを返す
      if (error.status === 401) {
        throw new Error('Qwen VL API: APIキーが無効です。QWEN_API_KEYを確認してください。');
      } else if (error.status === 429) {
        throw new Error('Qwen VL API: レート制限に達しました。しばらく待ってから再試行してください。');
      } else if (error.status === 500 || error.status === 503) {
        throw new Error('Qwen VL API: サーバーエラーが発生しました。しばらく待ってから再試行してください。');
      } else if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
        throw new Error(`Qwen VL API: タイムアウトしました（30秒）。リージョン設定(QWEN_REGION=${this.region})を確認するか、しばらく待ってから再試行してください。`);
      } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND' || error.message?.includes('Connection error')) {
        throw new Error(`Qwen VL API: ネットワーク接続エラー。リージョン設定(QWEN_REGION=${this.region})とインターネット接続を確認してください。`);
      } else if (error.code === 'ETIMEDOUT' || error.code === 'ESOCKETTIMEDOUT') {
        throw new Error('Qwen VL API: 接続タイムアウト。ネットワーク環境を確認してください。');
      }

      // より詳細なエラーメッセージを提供
      const errorDetails = error.message || JSON.stringify(error);
      throw new Error(`Qwen VL API error: ${errorDetails}. リージョン: ${this.region}`);
    }
  }
}
