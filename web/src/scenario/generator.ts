/**
 * タクシー観光ガイドシナリオ生成エンジン
 */

import { QwenClient } from '../qwen-client';
import { GeminiClient } from '../gemini-client';
import { RouteInput, SpotScenario, ScenarioOutput, ModelSelection, RouteSpot } from '../types/scenario';
import { buildPrompt, resolveLanguage } from './prompt-builder';

/**
 * タクシー観光ガイドシナリオジェネレーター
 * QwenとGeminiの両方のモデルを使用してシナリオを生成
 */
export class ScenarioGenerator {
  private qwenClient?: QwenClient;
  private geminiClient?: GeminiClient;

  /**
   * ScenarioGeneratorのコンストラクタ
   * @param qwenApiKey QwenのAPIキー（オプション）
   * @param geminiApiKey GeminiのAPIキー（オプション）
   * @param qwenRegion Qwenのリージョン設定（オプション）
   */
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
   * @param route ルート情報
   * @param models 使用するモデル（'qwen', 'qwen-vl', 'gemini', 'both'）
   * @returns シナリオ生成結果
   */
  async generateRoute(
    route: RouteInput,
    models: ModelSelection = 'both'
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
      this.generateSpot(route.routeName, spot, models, language)
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
   * @param routeName ルート名
   * @param spot 地点情報
   * @param models 使用するモデル（'qwen', 'qwen-vl', 'gemini', 'both'）
   * @param language 出力言語（'ja'または'en'）
   * @returns 地点のシナリオ
   */
  async generateSpot(
    routeName: string,
    spot: RouteSpot,
    models: ModelSelection = 'both',
    language: 'ja' | 'en' = 'en'
  ): Promise<SpotScenario> {
    const result: SpotScenario = {
      name: spot.name,
      type: spot.type,
      error: {},
    };

    const promises: Promise<void>[] = [];

    // 画像がある場合はQwen VLモデルを使用
    const useQwenVL = spot.imageUrl && this.qwenClient;

    // Qwen呼び出し(画像がある場合はVLモデル、ない場合は通常モデル)
    if ((models === 'qwen' || models === 'qwen-vl' || models === 'both') && this.qwenClient) {
      // Qwen VL使用時のみ画像指示を含める
      const qwenPrompt = buildPrompt(routeName, spot, language, useQwenVL);

      promises.push(
        (useQwenVL
          ? this.qwenClient.chatWithImage(qwenPrompt, spot.imageUrl!)
          : this.qwenClient.chat(qwenPrompt)
        )
          .then(response => {
            result.qwen = response;
          })
          .catch(error => {
            result.error!.qwen = error.message;
          })
      );
    }

    // Gemini呼び出し(画像指示は含めない)
    if ((models === 'gemini' || models === 'both') && this.geminiClient) {
      const geminiPrompt = buildPrompt(routeName, spot, language, false);

      promises.push(
        this.geminiClient.chat(geminiPrompt)
          .then(response => {
            result.gemini = response;
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

    return result;
  }

  /**
   * 単一地点のシナリオを生成（簡易版）
   * @param routeName ルート名
   * @param spotName 地点名
   * @param description 地点の説明（オプション）
   * @param point 観光ポイント（オプション）
   * @param models 使用するモデル（'qwen', 'qwen-vl', 'gemini', 'both'）
   * @returns QwenとGeminiの生成結果
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
