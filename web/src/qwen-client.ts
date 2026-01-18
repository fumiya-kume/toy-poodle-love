export class QwenClient {
  private apiKey: string;
  private baseURL: string;

  constructor(apiKey: string, region: 'china' | 'international' = 'international') {
    // Qwen uses OpenAI-compatible API via DashScope
    // International (Singapore/Virginia): dashscope-intl.aliyuncs.com
    // China (Beijing): dashscope.aliyuncs.com
    this.apiKey = apiKey;
    this.baseURL = region === 'china'
      ? 'https://dashscope.aliyuncs.com/compatible-mode/v1'
      : 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';
  }

  async chat(message: string): Promise<string> {
    const url = `${this.baseURL}/chat/completions`;

    try {
      console.log('Qwen API Request:', {
        url,
        hasApiKey: !!this.apiKey,
        apiKeyPrefix: this.apiKey.substring(0, 8) + '...',
      });

      const response = await fetch(url, {
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
        signal: AbortSignal.timeout(30000), // 30秒のタイムアウト
      });

      console.log('Qwen API Response Status:', response.status, response.statusText);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Qwen API Error Response:', errorText);

        if (response.status === 401) {
          throw new Error('Qwen API: APIキーが無効です。QWEN_API_KEYを確認してください。');
        } else if (response.status === 429) {
          throw new Error('Qwen API: レート制限に達しました。しばらく待ってから再試行してください。');
        } else if (response.status === 400) {
          throw new Error(`Qwen API: リクエストが無効です。${errorText}`);
        }

        throw new Error(`Qwen API: HTTP ${response.status} - ${errorText}`);
      }

      const data = await response.json();
      console.log('Qwen API Success:', { hasChoices: !!data.choices, choicesLength: data.choices?.length });

      return data.choices[0]?.message?.content || 'No response';
    } catch (error: any) {
      console.error('Qwen API Fetch Error:', {
        name: error.name,
        message: error.message,
        cause: error.cause,
      });

      if (error.name === 'AbortError' || error.name === 'TimeoutError') {
        throw new Error('Qwen API: リクエストがタイムアウトしました。ネットワーク接続を確認してください。');
      } else if (error.message && error.message.includes('fetch')) {
        throw new Error(`Qwen API: ネットワークエラー。${error.message}`);
      }

      throw error;
    }
  }
}
