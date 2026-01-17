/**
 * Prompt builder for taxi driver tour guide script generation
 * Supports automatic language detection based on input
 */

import { RouteSpot, OutputLanguage } from '../types/scenario';

/**
 * Detect if text contains Japanese characters
 */
function containsJapanese(text: string): boolean {
  // Match Hiragana, Katakana, or Kanji
  return /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]/.test(text);
}

/**
 * Detect language from spot data
 */
export function detectLanguage(spots: RouteSpot[]): 'ja' | 'en' {
  for (const spot of spots) {
    if (containsJapanese(spot.name)) return 'ja';
    if (spot.description && containsJapanese(spot.description)) return 'ja';
    if (spot.point && containsJapanese(spot.point)) return 'ja';
  }
  return 'en';
}

/**
 * Resolve the actual language to use
 */
export function resolveLanguage(
  language: OutputLanguage | undefined,
  spots: RouteSpot[]
): 'ja' | 'en' {
  if (language === 'ja' || language === 'en') {
    return language;
  }
  // auto or undefined: detect from input
  return detectLanguage(spots);
}

/**
 * Build a prompt from spot information
 */
export function buildPrompt(
  routeName: string,
  spot: RouteSpot,
  language: 'ja' | 'en' = 'en'
): string {
  const { name, type, description, point } = spot;
  const typeContext = getTypeContext(type, language);

  if (language === 'ja') {
    const spotInfo = [
      `地点名: ${name}`,
      description && `説明: ${description}`,
      point && `ポイント: ${point}`,
    ].filter(Boolean).join('\n');

    return `あなたは旅行ガイドのシナリオライターです。「${routeName}」というタクシー観光ルートで、乗客に観光ガイドをしています。

${typeContext}

# 地点情報
${spotInfo}

# 指示
この地点について、乗客に地点を説明するガイドのシナリオを生成してください。

# 要件
- 自然な話し言葉で、丁寧な敬語を使う
- 長さは2-3文程度（100-150文字程度）
- 地点の歴史的背景や文化的意義を優先的に紹介する
- その場所が「なぜ重要なのか」「どのような歴史的出来事があったのか」を伝える
- 「こちらは」などの呼びかけを含める
- 過度に教科書的にならず、親しみやすいトーンで

セリフのみを出力してください（説明や前置きは不要）。`;
  }

  // English
  const spotInfo = [
    `Location name: ${name}`,
    description && `Description: ${description}`,
    point && `Highlight: ${point}`,
  ].filter(Boolean).join('\n');

  return `You are a scenario writer for travel guides. You are providing a tour guide for passengers on a taxi sightseeing route called "${routeName}".

${typeContext}

# Location Information
${spotInfo}

# Instructions
Generate a guide script explaining this location to passengers.

# Requirements
- Use natural spoken language with polite expressions
- Length should be 2-3 sentences (approximately 50-100 words)
- Prioritize introducing the location's historical background and cultural significance
- Explain "why this place is important" and "what historical events occurred here"
- Include phrases like "Here we have..." or "On your left/right..."
- Keep a friendly, approachable tone without being overly academic

Output only the script (no explanations or preambles needed).`;
}

/**
 * Generate context based on spot type
 */
function getTypeContext(type: string, language: 'ja' | 'en'): string {
  if (language === 'ja') {
    switch (type) {
      case 'start':
        return '今から乗客を目的地に向かってお送りします。出発時のご挨拶をお願いします。';
      case 'waypoint':
        return '現在、このルート上の見どころを通過中です。車窓から見える景色について案内してください。';
      case 'destination':
        return '目的地に到着しました。到着の挨拶と、この場所の見どころを簡単にご案内ください。';
      default:
        return 'この地点について案内してください。';
    }
  }

  // English
  switch (type) {
    case 'start':
      return 'You are about to take passengers to their destination. Please provide a departure greeting.';
    case 'waypoint':
      return 'You are currently passing through a highlight on this route. Please describe the scenery visible from the car window.';
    case 'destination':
      return 'You have arrived at the destination. Please give an arrival greeting and briefly introduce the highlights of this place.';
    default:
      return 'Please guide passengers about this location.';
  }
}

/**
 * Get system prompt based on language
 */
export function getSystemPrompt(language: 'ja' | 'en'): string {
  if (language === 'ja') {
    return 'あなたは経験豊富なタクシードライバーです。東京の観光名所に詳しく、特に各地点の歴史的背景や文化的重要性についての知識が豊富です。乗客に親しみやすく丁寧なガイドを提供し、その土地の歴史や由来を分かりやすく伝えます。';
  }
  return 'You are an experienced taxi driver. You are knowledgeable about Tokyo\'s tourist attractions, with deep expertise in the historical background and cultural significance of each location. You provide friendly, polite guidance to passengers, sharing the history and origins of each place in an easy-to-understand manner.';
}

/**
 * System prompt (for backward compatibility)
 */
export const SYSTEM_PROMPT = getSystemPrompt('en');
