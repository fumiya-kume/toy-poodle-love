/**
 * Prompt builder for scenario integration
 * Supports automatic language detection based on input
 */

import { SpotScenario } from '../types/scenario';

/**
 * Detect if text contains Japanese characters
 */
function containsJapanese(text: string): boolean {
  return /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]/.test(text);
}

/**
 * Detect language from scenario content
 */
export function detectLanguageFromScenarios(
  spots: SpotScenario[],
  sourceModel: 'qwen' | 'gemini'
): 'ja' | 'en' {
  for (const spot of spots) {
    const content = sourceModel === 'qwen' ? spot.qwen : spot.gemini;
    if (content && containsJapanese(content)) {
      return 'ja';
    }
  }
  return 'en';
}

/**
 * Build integration prompt
 */
export function buildIntegrationPrompt(
  routeName: string,
  spots: SpotScenario[],
  sourceModel: 'qwen' | 'gemini',
  language?: 'ja' | 'en'
): string {
  // Auto-detect language if not specified
  const lang = language || detectLanguageFromScenarios(spots, sourceModel);

  // Extract scenario for each spot
  const scenarioSections = spots
    .map((spot) => {
      const scenario = sourceModel === 'qwen' ? spot.qwen : spot.gemini;
      return scenario || null;
    })
    .filter(Boolean)
    .join('\n\n');

  if (lang === 'ja') {
    return `あなたは旅行ガイドのシナリオ編集者です。「${routeName}」というタクシー観光ルートで生成された各地点のガイドシナリオを、1つの自然な流れのテキストに統合する作業をします。

# 各地点のシナリオ
${scenarioSections}

# 指示
上記の各地点のシナリオを、以下の要件に従って1つの自然な流れのテキストに統合してください。

# 要件
1. 各地点のシナリオ内容は基本的に保持し、大きく変更しない
2. 地点と地点の間に自然なつなぎのセリフを追加する
   - 例: 「それでは次の目的地に向かいましょう」
   - 例: 「少し走ると、次は〜が見えてきます」
3. 全体として自然な観光ガイドの流れになるようにする
4. 丁寧な敬語を使用する
5. 過度に長くせず、簡潔に

# 出力形式
統合されたシナリオテキストのみを出力してください（説明や前置きは不要）。
マークダウン記法や見出しは使用せず、プレーンテキストで出力してください。`;
  }

  // English
  return `You are a scenario editor for travel guides. Your task is to integrate the guide scripts generated for each location on the "${routeName}" taxi sightseeing route into one natural, flowing text.

# Scripts for Each Location
${scenarioSections}

# Instructions
Integrate the above scripts for each location into one natural, flowing text according to the following requirements.

# Requirements
1. Basically preserve the content of each location's script without major changes
2. Add natural transition lines between locations
   - Example: "Now let's head to our next destination"
   - Example: "As we drive a little further, you'll see..."
3. Ensure the overall flow feels like a natural tour guide experience
4. Use polite, professional language
5. Keep it concise without making it overly long

# Output Format
Output only the integrated scenario text (no explanations or preambles needed).
Do not use markdown formatting or headings; output in plain text.`;
}

/**
 * Get integration system prompt based on language
 */
export function getIntegrationSystemPrompt(language: 'ja' | 'en'): string {
  if (language === 'ja') {
    return 'あなたは経験豊富なシナリオ編集者です。観光ガイドのシナリオを自然な流れに整える作業が得意です。';
  }
  return 'You are an experienced scenario editor. You excel at arranging tour guide scripts into a natural flow.';
}

/**
 * System prompt (for backward compatibility)
 */
export const INTEGRATION_SYSTEM_PROMPT = getIntegrationSystemPrompt('en');
