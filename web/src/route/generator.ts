/**
 * タクシー観光ルート自動生成エンジン
 */

import { QwenClient } from '../qwen-client';
import { GeminiClient } from '../gemini-client';
import { RouteGenerationInput, RouteGenerationOutput, GeneratedRouteSpot } from '../types/route';
import { buildRouteGenerationPrompt, resolveLanguage } from './prompt-builder';

interface ParsedRouteResponse {
  routeName: string;
  spots: GeneratedRouteSpot[];
}

export class RouteGenerator {
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
   * ルートを自動生成
   */
  async generate(input: RouteGenerationInput): Promise<RouteGenerationOutput> {
    const startTime = Date.now();
    const language = resolveLanguage(input.language, input);
    const prompt = buildRouteGenerationPrompt(input, language);

    let response: string;

    if (input.model === 'qwen') {
      if (!this.qwenClient) {
        throw new Error('Qwen API key is not configured');
      }
      response = await this.qwenClient.chat(prompt);
    } else {
      if (!this.geminiClient) {
        throw new Error('Gemini API key is not configured');
      }
      response = await this.geminiClient.chat(prompt);
    }

    const parsed = this.parseResponse(response);
    const processingTimeMs = Date.now() - startTime;

    return {
      generatedAt: new Date().toISOString(),
      routeName: parsed.routeName,
      spots: parsed.spots,
      model: input.model,
      processingTimeMs,
    };
  }

  /**
   * LLMレスポンスをパースしてルート情報を抽出
   */
  private parseResponse(response: string): ParsedRouteResponse {
    // JSONブロックを抽出（```json ... ``` または { ... }）
    const jsonMatch = response.match(/```json\s*([\s\S]*?)\s*```/) ||
                      response.match(/(\{[\s\S]*"routeName"[\s\S]*"spots"[\s\S]*\})/);

    if (!jsonMatch) {
      throw new Error('Failed to extract JSON from LLM response');
    }

    const jsonStr = jsonMatch[1] || jsonMatch[0];

    try {
      const parsed = JSON.parse(jsonStr);

      if (!parsed.routeName || !Array.isArray(parsed.spots)) {
        throw new Error('Invalid JSON structure: missing routeName or spots');
      }

      // spotsの検証と正規化
      const spots: GeneratedRouteSpot[] = parsed.spots.map((spot: Record<string, unknown>, index: number) => {
        if (!spot.name) {
          throw new Error(`Spot at index ${index} is missing name`);
        }

        // typeの正規化
        let type: 'start' | 'waypoint' | 'destination' = 'waypoint';
        if (index === 0) {
          type = 'start';
        } else if (index === parsed.spots.length - 1) {
          type = 'destination';
        } else if (spot.type === 'start' || spot.type === 'waypoint' || spot.type === 'destination') {
          type = spot.type as 'start' | 'waypoint' | 'destination';
        }

        return {
          name: String(spot.name),
          type,
          description: spot.description ? String(spot.description) : undefined,
          point: spot.point ? String(spot.point) : undefined,
          generatedNote: spot.generatedNote ? String(spot.generatedNote) : undefined,
        };
      });

      return {
        routeName: String(parsed.routeName),
        spots,
      };
    } catch (error) {
      if (error instanceof SyntaxError) {
        throw new Error(`Failed to parse JSON: ${error.message}`);
      }
      throw error;
    }
  }
}
