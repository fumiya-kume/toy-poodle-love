import { NextResponse } from 'next/server';
import { hasQwenApiKey, hasGeminiApiKey, hasGoogleMapsApiKey } from './env';

export type ApiKeyType = 'qwen' | 'gemini' | 'googleMaps';

const API_KEY_NAMES: Record<ApiKeyType, string> = {
  qwen: 'QWEN_API_KEY',
  gemini: 'GEMINI_API_KEY',
  googleMaps: 'GOOGLE_MAPS_API_KEY',
};

const API_KEY_CHECKERS: Record<ApiKeyType, () => boolean> = {
  qwen: hasQwenApiKey,
  gemini: hasGeminiApiKey,
  googleMaps: hasGoogleMapsApiKey,
};

/**
 * APIキーの存在を確認し、ない場合はエラーレスポンスを返す
 * @returns エラーレスポンス、またはnull（キーが存在する場合）
 */
export function requireApiKey(keyType: ApiKeyType): NextResponse | null {
  if (API_KEY_CHECKERS[keyType]()) {
    return null;
  }

  return NextResponse.json(
    {
      success: false,
      error: `${API_KEY_NAMES[keyType]} is not configured`,
    },
    { status: 500 }
  );
}

/**
 * 複数のAPIキーを確認
 */
export function requireApiKeys(keyTypes: ApiKeyType[]): NextResponse | null {
  for (const keyType of keyTypes) {
    const error = requireApiKey(keyType);
    if (error) return error;
  }
  return null;
}
