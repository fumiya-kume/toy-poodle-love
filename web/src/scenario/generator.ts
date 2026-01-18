/**
 * タクシー観光ガイドシナリオ生成エンジン
 */

import { QwenClient } from '../qwen-client';
import { GeminiClient } from '../gemini-client';
import { RouteInput, SpotScenario, ScenarioOutput, ModelSelection, RouteSpot } from '../types/scenario';
import { buildPrompt, resolveLanguage } from './prompt-builder';

/**
 * LLMからのレスポンスをパースする
 * JSON形式の場合はscenarioとimagePromptを抽出、それ以外はそのまま返す
 */
function parseLLMResponse(response: string): { scenario: string; imagePrompt?: string } {
  // JSONコードブロックを抽出（```json ... ```）
  const jsonMatch = response.match(/```json\s*\n([\s\S]*?)\n```/);

  if (jsonMatch) {
    try {
      const parsed = JSON.parse(jsonMatch[1]);
      return {
        scenario: parsed.scenario || response,
        imagePrompt: parsed.imagePrompt,
      };
    } catch {
      // JSONパースに失敗した場合は元のテキストを返す
      return { scenario: response };
    }
  }

  // JSONコードブロックがない場合、直接JSONとしてパース
  try {
    const parsed = JSON.parse(response);
    if (parsed.scenario) {
      return {
        scenario: parsed.scenario,
        imagePrompt: parsed.imagePrompt,
      };
    }
  } catch {
    // JSONでない場合は元のテキストをそのまま返す
  }

  return { scenario: response };
}

export class ScenarioGenerator {
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
   * ルート全体のシナリオを生成
   */
  async generateRoute(
    route: RouteInput,
    models: ModelSelection = 'both',
    includeImagePrompt: boolean = false
  ): Promise<ScenarioOutput> {
    const startTime = Date.now();

    // Resolve language from input data
    const language = resolveLanguage(route.language, route.spots);

    // start/destinationを除外してwaypointのみを処理
    const spotsToProcess = route.spots.filter(spot =>
      spot.type === 'waypoint' || spot.type === 'destination'
    );

    // 全地点を並列処理
    const spotPromises = spotsToProcess.map(spot =>
      this.generateSpot(route.routeName, spot, models, language, includeImagePrompt)
    );

    const results = await Promise.all(spotPromises);

    const processingTimeMs = Date.now() - startTime;

    // 統計情報を集計
    const stats = {
      totalSpots: spotsToProcess.length,
      successCount: {
        qwen: results.filter(r => r.qwen && !r.error?.qwen).length,
        gemini: results.filter(r => r.gemini && !r.error?.gemini).length,
      },
      processingTimeMs,
    };

    return {
      generatedAt: new Date().toISOString(),
      routeName: route.routeName,
      spots: results,
      stats,
    };
  }

  /**
   * 単一地点のシナリオを生成（Qwen/Gemini並列）
   */
  async generateSpot(
    routeName: string,
    spot: RouteSpot,
    models: ModelSelection = 'both',
    language: 'ja' | 'en' = 'en',
    includeImagePrompt: boolean = false
  ): Promise<SpotScenario> {
    const prompt = buildPrompt(routeName, spot, language, includeImagePrompt);

    const result: SpotScenario = {
      name: spot.name,
      type: spot.type,
      error: {},
    };

    if (includeImagePrompt) {
      result.imagePrompt = {};
    }

    const promises: Promise<void>[] = [];

    // Qwen呼び出し
    if ((models === 'qwen' || models === 'both') && this.qwenClient) {
      promises.push(
        this.qwenClient.chat(prompt)
          .then(response => {
            const parsed = parseLLMResponse(response);
            result.qwen = parsed.scenario;
            if (includeImagePrompt && parsed.imagePrompt) {
              result.imagePrompt!.qwen = parsed.imagePrompt;
            }
          })
          .catch(error => {
            result.error!.qwen = error.message;
          })
      );
    }

    // Gemini呼び出し
    if ((models === 'gemini' || models === 'both') && this.geminiClient) {
      promises.push(
        this.geminiClient.chat(prompt)
          .then(response => {
            const parsed = parseLLMResponse(response);
            result.gemini = parsed.scenario;
            if (includeImagePrompt && parsed.imagePrompt) {
              result.imagePrompt!.gemini = parsed.imagePrompt;
            }
          })
          .catch(error => {
            result.error!.gemini = error.message;
          })
      );
    }

    // 両方の呼び出しを並列実行
    await Promise.all(promises);

    // エラーがなければerrorフィールドを削除
    if (!result.error?.qwen && !result.error?.gemini) {
      delete result.error;
    }

    // imagePromptが空なら削除
    if (result.imagePrompt && !result.imagePrompt.qwen && !result.imagePrompt.gemini) {
      delete result.imagePrompt;
    }

    return result;
  }

  /**
   * 単一地点のシナリオを生成（簡易版）
   */
  async generateSingleSpot(
    routeName: string,
    spotName: string,
    description?: string,
    point?: string,
    models: ModelSelection = 'both'
  ): Promise<{ qwen?: string; gemini?: string }> {
    const spot: RouteSpot = {
      name: spotName,
      type: 'waypoint',
      description,
      point,
    };

    const result = await this.generateSpot(routeName, spot, models);

    return {
      qwen: result.qwen,
      gemini: result.gemini,
    };
  }
}
