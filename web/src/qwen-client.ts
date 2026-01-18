import OpenAI from 'openai';

export class QwenClient {
  private client: OpenAI;

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
  }

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
      });

      if (error.status === 401) {
        throw new Error('Qwen API: APIキーが無効です。QWEN_API_KEYを確認してください。');
      } else if (error.status === 429) {
        throw new Error('Qwen API: レート制限に達しました。しばらく待ってから再試行してください。');
      } else if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
        throw new Error('Qwen API: ネットワーク接続エラー。リージョン設定(QWEN_REGION)を確認してください。');
      }

      throw new Error(`Qwen API error: ${error.message || error}`);
    }
  }
}
