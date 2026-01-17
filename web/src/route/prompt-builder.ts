/**
 * ルート自動生成用プロンプトビルダー
 */

import { RouteGenerationInput } from '../types/route';
import { OutputLanguage } from '../types/scenario';

/**
 * テキストに日本語が含まれているか判定
 */
function containsJapanese(text: string): boolean {
  return /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]/.test(text);
}

/**
 * 入力から言語を検出
 */
export function detectLanguageFromInput(input: RouteGenerationInput): 'ja' | 'en' {
  if (containsJapanese(input.startPoint) || containsJapanese(input.purpose)) {
    return 'ja';
  }
  return 'en';
}

/**
 * 言語を解決
 */
export function resolveLanguage(
  language: OutputLanguage | undefined,
  input: RouteGenerationInput
): 'ja' | 'en' {
  if (language === 'ja' || language === 'en') {
    return language;
  }
  return detectLanguageFromInput(input);
}

/**
 * ルート生成用プロンプトを構築
 */
export function buildRouteGenerationPrompt(
  input: RouteGenerationInput,
  language: 'ja' | 'en'
): string {
  const { startPoint, purpose, spotCount } = input;

  if (language === 'ja') {
    return `あなたはタクシー観光ルートプランナーです。乗客の希望に基づいて、最適な観光ルートを提案してください。

# 入力情報
- スタート地点: ${startPoint}
- 目的・テーマ: ${purpose}
- 希望地点数: ${spotCount}

# 指示
上記の情報から、タクシー観光に適したルートを計画してください。
最初の地点はスタート地点、最後の地点は目的地として設定してください。
中間の地点はルート上の見どころとなる経由地です。

# 出力形式
必ず以下のJSON形式で出力してください。他の説明やコメントは一切不要です。

\`\`\`json
{
  "routeName": "ルート名（例: 東京駅→皇居コース）",
  "spots": [
    {
      "name": "地点名",
      "type": "start",
      "description": "地点の簡単な説明",
      "point": "観光ポイント・見どころ"
    },
    {
      "name": "地点名",
      "type": "waypoint",
      "description": "地点の簡単な説明",
      "point": "観光ポイント・見どころ"
    },
    {
      "name": "地点名",
      "type": "destination",
      "description": "地点の簡単な説明",
      "point": "観光ポイント・見どころ"
    }
  ]
}
\`\`\`

# 要件
- typeは必ず最初が"start"、最後が"destination"、それ以外は"waypoint"
- 地点数は必ず${spotCount}個
- 各地点にはdescriptionとpointを含める
- 実在する場所のみを使用
- 観光客に人気があり、タクシーで回れるルートを考慮`;
  }

  // English
  return `You are a taxi tour route planner. Plan an optimal sightseeing route based on passenger preferences.

# Input Information
- Start Point: ${startPoint}
- Purpose/Theme: ${purpose}
- Desired Number of Spots: ${spotCount}

# Instructions
Based on the above information, plan a route suitable for taxi sightseeing.
Set the first spot as the start point and the last spot as the destination.
Intermediate spots are waypoints with highlights along the route.

# Output Format
Output in the following JSON format only. No other explanations or comments needed.

\`\`\`json
{
  "routeName": "Route name (e.g., Tokyo Station → Imperial Palace Course)",
  "spots": [
    {
      "name": "Spot name",
      "type": "start",
      "description": "Brief description of the spot",
      "point": "Tourist highlight"
    },
    {
      "name": "Spot name",
      "type": "waypoint",
      "description": "Brief description of the spot",
      "point": "Tourist highlight"
    },
    {
      "name": "Spot name",
      "type": "destination",
      "description": "Brief description of the spot",
      "point": "Tourist highlight"
    }
  ]
}
\`\`\`

# Requirements
- type must be "start" for first, "destination" for last, "waypoint" for others
- Exactly ${spotCount} spots
- Include description and point for each spot
- Use only real, existing locations
- Consider routes popular with tourists and accessible by taxi`;
}
