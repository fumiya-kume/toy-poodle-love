/**
 * Next.js Instrumentation
 * サーバー起動時に環境変数をバリデーション
 */

export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { getEnv } = await import('./src/config');

    const env = getEnv();

    console.log('[ENV] Environment loaded:', {
      hasQwenApiKey: !!env.qwenApiKey,
      hasGeminiApiKey: !!env.geminiApiKey,
      hasGoogleMapsApiKey: !!env.googleMapsApiKey,
      qwenRegion: env.qwenRegion,
    });

    const missing: string[] = [];
    if (!env.qwenApiKey) missing.push('QWEN_API_KEY');
    if (!env.geminiApiKey) missing.push('GEMINI_API_KEY');
    if (!env.googleMapsApiKey) missing.push('GOOGLE_MAPS_API_KEY');

    if (missing.length > 0) {
      console.warn(`[ENV] Warning: Missing API keys: ${missing.join(', ')}`);
      console.warn('[ENV] Some features may not work correctly.');
    }
  }
}
