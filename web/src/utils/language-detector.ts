/**
 * 言語検出ユーティリティ
 * 文字コード範囲ベースで簡易的に言語を判定
 */

import { OutputLanguage } from '../types/scenario';

/**
 * テキストから言語を検出
 */
export function detectLanguage(text: string): Exclude<OutputLanguage, 'auto'> {
  // 空文字の場合はデフォルトで日本語
  if (!text || text.trim().length === 0) {
    return 'ja';
  }

  const trimmed = text.trim();

  // ひらがな・カタカナが含まれる場合は日本語
  if (/[\u3040-\u309F\u30A0-\u30FF]/.test(trimmed)) {
    return 'ja';
  }

  // CJK漢字のみ（日本語の仮名なし）の場合は中国語
  // 漢字範囲: U+4E00-U+9FFF
  const hasCJK = /[\u4E00-\u9FFF]/.test(trimmed);
  const hasAlpha = /[a-zA-Z]/.test(trimmed);

  if (hasCJK && !hasAlpha) {
    return 'zh';
  }

  // アルファベットが主な場合は英語
  if (hasAlpha) {
    return 'en';
  }

  // その他の場合は日本語をデフォルトとする
  return 'ja';
}

/**
 * 複数のテキストから言語を検出（結合して判定）
 */
export function detectLanguageFromTexts(texts: (string | undefined)[]): Exclude<OutputLanguage, 'auto'> {
  const combined = texts
    .filter((t): t is string => typeof t === 'string' && t.trim().length > 0)
    .join(' ');

  return detectLanguage(combined);
}
