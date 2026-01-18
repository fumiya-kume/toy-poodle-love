import { GoogleGenerativeAI } from '@google/generative-ai';

/**
 * Gemini APIクライアント
 * Google Generative AIを使用したテキスト生成
 */
export class GeminiClient {
  private genAI: GoogleGenerativeAI;
  private model: any;

  /**
   * GeminiClientのコンストラクタ
   * @param apiKey Google AI StudioのAPIキー
   */
  constructor(apiKey: string) {
    this.genAI = new GoogleGenerativeAI(apiKey);
    // Using Gemini 1.5 Flash model (faster and more cost-effective)
    // Alternative: 'gemini-1.5-pro' for more advanced capabilities
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  }

  /**
   * テキスト生成
   * @param message ユーザーメッセージ
   * @returns レスポンステキスト
   */
  async chat(message: string): Promise<string> {
    try {
      const result = await this.model.generateContent(message);
      const response = await result.response;
      return response.text();
    } catch (error) {
      throw new Error(`Gemini API error: ${error}`);
    }
  }
}
