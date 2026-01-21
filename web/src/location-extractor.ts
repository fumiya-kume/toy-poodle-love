/**
 * 会話テキストからLLMを使って出発地・目的地を抽出するサービス
 */

import { QwenClient } from './qwen-client';
import { GeminiClient } from './gemini-client';
import { ExtractedLocation } from './types/voice-route';
import { getEnv } from './config';

/**
 * 地点抽出用のプロンプトを生成
 */
function buildExtractionPrompt(text: string): string {
  return `あなたはタクシー配車システムの会話解析AIです。
以下の会話テキストから、ユーザーの「出発地」「目的地」「経由地点」を抽出してください。

## ルール
1. 出発地点は「〜から」「〜を出発」「今〜にいる」などの表現から判断
2. 目的地は「〜まで」「〜に行きたい」「〜へ」などの表現から判断
3. 経由地点は「〜経由で」「〜に寄って」「途中で〜」などの表現から判断
4. 明確に特定できない場合は null を設定
5. 地名、駅名、建物名、住所などを正確に抽出

## 会話テキスト
"""
${text}
"""

## 出力形式
必ず以下のJSON形式で出力してください。JSONのみを出力し、他の説明は不要です。

\`\`\`json
{
  "origin": "出発地点（不明な場合はnull）",
  "destination": "目的地（不明な場合はnull）",
  "waypoints": ["経由地点1", "経由地点2"],
  "confidence": 0.0～1.0の数値（抽出の確信度）,
  "interpretation": "会話の解釈の説明"
}
\`\`\``;
}

/**
 * LLMのレスポンスからJSONを抽出
 */
function parseExtractedLocation(response: string): ExtractedLocation {
  // ```json ... ``` ブロックを探す
  const jsonBlockMatch = response.match(/```json\s*([\s\S]*?)```/);
  let jsonStr = jsonBlockMatch ? jsonBlockMatch[1].trim() : response.trim();

  // JSONオブジェクトを直接探す
  if (!jsonBlockMatch) {
    const jsonMatch = jsonStr.match(/\{[\s\S]*"origin"[\s\S]*"destination"[\s\S]*\}/);
    if (jsonMatch) {
      jsonStr = jsonMatch[0];
    }
  }

  try {
    const parsed = JSON.parse(jsonStr);
    return {
      origin: parsed.origin || null,
      destination: parsed.destination || null,
      waypoints: Array.isArray(parsed.waypoints) ? parsed.waypoints : [],
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.5,
      interpretation: parsed.interpretation || '',
    };
  } catch (error) {
    console.error('Failed to parse LLM response:', error, 'Response:', response);
    throw new Error('LLMからの応答を解析できませんでした');
  }
}

export class LocationExtractor {
  private qwenClient: QwenClient | null = null;
  private geminiClient: GeminiClient | null = null;

  constructor() {
    const env = getEnv();
    // 利用可能なクライアントを初期化
    if (env.qwenApiKey) {
      this.qwenClient = new QwenClient(env.qwenApiKey, env.qwenRegion);
    }
    if (env.geminiApiKey) {
      this.geminiClient = new GeminiClient(env.geminiApiKey);
    }
  }

  /**
   * 会話テキストから地点を抽出
   */
  async extract(text: string, model: 'qwen' | 'gemini' = 'gemini'): Promise<ExtractedLocation> {
    const prompt = buildExtractionPrompt(text);

    let response: string;

    if (model === 'gemini') {
      if (!this.geminiClient) {
        throw new Error('Gemini APIキーが設定されていません');
      }
      response = await this.geminiClient.chat(prompt);
    } else {
      if (!this.qwenClient) {
        throw new Error('Qwen APIキーが設定されていません');
      }
      response = await this.qwenClient.chat(prompt);
    }

    console.log('Location extraction response:', response);

    return parseExtractedLocation(response);
  }
}
