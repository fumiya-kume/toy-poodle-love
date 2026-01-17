/**
 * シナリオ統合エンジン
 */

import { QwenClient } from '../qwen-client';
import { GeminiClient } from '../gemini-client';
import { ScenarioIntegrationInput, ScenarioIntegrationOutput } from '../types/scenario';
import { buildIntegrationPrompt } from './integration-prompt-builder';

export class ScenarioIntegrator {
  private qwenClient?: QwenClient;
  private geminiClient?: GeminiClient;

  constructor(
    qwenApiKey?: string,
    geminiApiKey?: string,
    qwenRegion?: 'china' | 'international'
  ) {
    if (qwenApiKey) {
      this.qwenClient = new QwenClient(qwenApiKey, qwenRegion);
    }
    if (geminiApiKey) {
      this.geminiClient = new GeminiClient(geminiApiKey);
    }
  }

  /**
   * シナリオを統合
   */
  async integrate(input: ScenarioIntegrationInput): Promise<ScenarioIntegrationOutput> {
    const startTime = Date.now();

    // 統合に使用するLLMを決定（省略時はsourceModelと異なる方）
    const integrationLLM = input.integrationLLM ||
      (input.sourceModel === 'qwen' ? 'gemini' : 'qwen');

    // 統合用プロンプトを構築
    const prompt = buildIntegrationPrompt(
      input.routeName,
      input.spots,
      input.sourceModel
    );

    // 選択されたLLMで統合処理を実行
    let integratedScript: string;

    if (integrationLLM === 'qwen') {
      if (!this.qwenClient) {
        throw new Error('Qwen APIキーが設定されていません');
      }
      integratedScript = await this.qwenClient.chat(prompt);
    } else {
      if (!this.geminiClient) {
        throw new Error('Gemini APIキーが設定されていません');
      }
      integratedScript = await this.geminiClient.chat(prompt);
    }

    const processingTimeMs = Date.now() - startTime;

    return {
      integratedAt: new Date().toISOString(),
      routeName: input.routeName,
      sourceModel: input.sourceModel,
      integrationLLM,
      integratedScript,
      processingTimeMs,
    };
  }
}
