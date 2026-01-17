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
      });

      return response.choices[0]?.message?.content || 'No response';
    } catch (error) {
      throw new Error(`Qwen API error: ${error}`);
    }
  }
}
