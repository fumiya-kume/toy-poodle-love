import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  initializeDotenv,
  getEnv,
  hasQwenApiKey,
  hasGeminiApiKey,
  hasGoogleMapsApiKey,
  hasLangfuseKeys,
  isLangfuseEnabled,
  validateRequiredKeys,
  clearEnvCache,
} from './env'

// dotenvモジュールをモック
vi.mock('dotenv', () => ({
  config: vi.fn(),
}))

describe('env', () => {
  let originalEnv: NodeJS.ProcessEnv
  let consoleWarnSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    // 元の環境変数を保存
    originalEnv = { ...process.env }
    // キャッシュをクリア
    clearEnvCache()
    // console.warnをモック
    consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
  })

  afterEach(() => {
    // 環境変数を復元
    process.env = originalEnv
    consoleWarnSpy.mockRestore()
  })

  describe('initializeDotenv', () => {
    it('Next.js環境では自動読み込みをスキップする', async () => {
      process.env.NEXT_RUNTIME = 'nodejs'
      const dotenv = await import('dotenv')

      clearEnvCache()
      initializeDotenv()

      expect(dotenv.config).not.toHaveBeenCalled()
    })

    it('CLI環境ではdotenv.configを呼び出す', async () => {
      delete process.env.NEXT_RUNTIME
      const dotenv = await import('dotenv')
      vi.mocked(dotenv.config).mockClear()

      clearEnvCache()
      initializeDotenv()

      expect(dotenv.config).toHaveBeenCalled()
    })

    it('二度目の呼び出しでは何もしない', async () => {
      delete process.env.NEXT_RUNTIME
      const dotenv = await import('dotenv')
      vi.mocked(dotenv.config).mockClear()

      clearEnvCache()
      initializeDotenv()
      initializeDotenv()

      expect(dotenv.config).toHaveBeenCalledTimes(1)
    })
  })

  describe('getEnv', () => {
    it('環境変数をキャッシュする', () => {
      process.env.QWEN_API_KEY = 'test-key-1'
      const env1 = getEnv()

      process.env.QWEN_API_KEY = 'test-key-2'
      const env2 = getEnv()

      expect(env1).toBe(env2)
      expect(env1.qwenApiKey).toBe('test-key-1')
    })

    it('キャッシュをクリアすると再取得する', () => {
      process.env.QWEN_API_KEY = 'test-key-1'
      const env1 = getEnv()

      clearEnvCache()
      process.env.QWEN_API_KEY = 'test-key-2'
      const env2 = getEnv()

      expect(env1.qwenApiKey).toBe('test-key-1')
      expect(env2.qwenApiKey).toBe('test-key-2')
    })

    describe('QWEN_REGION', () => {
      it('chinaを正しく解析する', () => {
        process.env.QWEN_REGION = 'china'
        clearEnvCache()

        const env = getEnv()
        expect(env.qwenRegion).toBe('china')
      })

      it('internationalを正しく解析する', () => {
        process.env.QWEN_REGION = 'international'
        clearEnvCache()

        const env = getEnv()
        expect(env.qwenRegion).toBe('international')
      })

      it('無効な値はinternationalにフォールバックする', () => {
        process.env.QWEN_REGION = 'invalid'
        clearEnvCache()

        const env = getEnv()
        expect(env.qwenRegion).toBe('international')
        expect(consoleWarnSpy).toHaveBeenCalledWith(
          expect.stringContaining('Invalid QWEN_REGION value')
        )
      })

      it('未設定の場合はデフォルト値を使用する', () => {
        delete process.env.QWEN_REGION
        clearEnvCache()

        const env = getEnv()
        expect(env.qwenRegion).toBe('international')
      })
    })

    describe('LANGFUSE_ENABLED', () => {
      it('trueを正しく解析する', () => {
        process.env.LANGFUSE_ENABLED = 'true'
        clearEnvCache()

        const env = getEnv()
        expect(env.langfuseEnabled).toBe(true)
      })

      it('falseを正しく解析する', () => {
        process.env.LANGFUSE_ENABLED = 'false'
        clearEnvCache()

        const env = getEnv()
        expect(env.langfuseEnabled).toBe(false)
      })

      it('0を正しく解析する', () => {
        process.env.LANGFUSE_ENABLED = '0'
        clearEnvCache()

        const env = getEnv()
        expect(env.langfuseEnabled).toBe(false)
      })

      it('空文字以外の値はtrueとして解析する', () => {
        process.env.LANGFUSE_ENABLED = '1'
        clearEnvCache()

        const env = getEnv()
        expect(env.langfuseEnabled).toBe(true)
      })
    })

    describe('APIキーの取得', () => {
      it('全てのAPIキーを正しく取得する', () => {
        process.env.QWEN_API_KEY = 'qwen-key'
        process.env.GEMINI_API_KEY = 'gemini-key'
        process.env.GOOGLE_MAPS_API_KEY = 'maps-key'
        clearEnvCache()

        const env = getEnv()
        expect(env.qwenApiKey).toBe('qwen-key')
        expect(env.geminiApiKey).toBe('gemini-key')
        expect(env.googleMapsApiKey).toBe('maps-key')
      })

      it('未設定のAPIキーはundefinedになる', () => {
        delete process.env.QWEN_API_KEY
        delete process.env.GEMINI_API_KEY
        delete process.env.GOOGLE_MAPS_API_KEY
        clearEnvCache()

        const env = getEnv()
        expect(env.qwenApiKey).toBeUndefined()
        expect(env.geminiApiKey).toBeUndefined()
        expect(env.googleMapsApiKey).toBeUndefined()
      })
    })
  })

  describe('hasXxxApiKey', () => {
    it('hasQwenApiKeyがキー存在時にtrueを返す', () => {
      process.env.QWEN_API_KEY = 'test-key'
      clearEnvCache()

      expect(hasQwenApiKey()).toBe(true)
    })

    it('hasQwenApiKeyがキー不在時にfalseを返す', () => {
      delete process.env.QWEN_API_KEY
      clearEnvCache()

      expect(hasQwenApiKey()).toBe(false)
    })

    it('hasGeminiApiKeyがキー存在時にtrueを返す', () => {
      process.env.GEMINI_API_KEY = 'test-key'
      clearEnvCache()

      expect(hasGeminiApiKey()).toBe(true)
    })

    it('hasGeminiApiKeyがキー不在時にfalseを返す', () => {
      delete process.env.GEMINI_API_KEY
      clearEnvCache()

      expect(hasGeminiApiKey()).toBe(false)
    })

    it('hasGoogleMapsApiKeyがキー存在時にtrueを返す', () => {
      process.env.GOOGLE_MAPS_API_KEY = 'test-key'
      clearEnvCache()

      expect(hasGoogleMapsApiKey()).toBe(true)
    })

    it('hasGoogleMapsApiKeyがキー不在時にfalseを返す', () => {
      delete process.env.GOOGLE_MAPS_API_KEY
      clearEnvCache()

      expect(hasGoogleMapsApiKey()).toBe(false)
    })
  })

  describe('hasLangfuseKeys', () => {
    it('両方のキーが存在する場合はtrueを返す', () => {
      process.env.LANGFUSE_SECRET_KEY = 'secret'
      process.env.LANGFUSE_PUBLIC_KEY = 'public'
      clearEnvCache()

      expect(hasLangfuseKeys()).toBe(true)
    })

    it('secretKeyのみの場合はfalseを返す', () => {
      process.env.LANGFUSE_SECRET_KEY = 'secret'
      delete process.env.LANGFUSE_PUBLIC_KEY
      clearEnvCache()

      expect(hasLangfuseKeys()).toBe(false)
    })

    it('publicKeyのみの場合はfalseを返す', () => {
      delete process.env.LANGFUSE_SECRET_KEY
      process.env.LANGFUSE_PUBLIC_KEY = 'public'
      clearEnvCache()

      expect(hasLangfuseKeys()).toBe(false)
    })
  })

  describe('isLangfuseEnabled', () => {
    it('有効かつキーが存在する場合はtrueを返す', () => {
      process.env.LANGFUSE_ENABLED = 'true'
      process.env.LANGFUSE_SECRET_KEY = 'secret'
      process.env.LANGFUSE_PUBLIC_KEY = 'public'
      clearEnvCache()

      expect(isLangfuseEnabled()).toBe(true)
    })

    it('無効の場合はfalseを返す', () => {
      process.env.LANGFUSE_ENABLED = 'false'
      process.env.LANGFUSE_SECRET_KEY = 'secret'
      process.env.LANGFUSE_PUBLIC_KEY = 'public'
      clearEnvCache()

      expect(isLangfuseEnabled()).toBe(false)
    })

    it('キーが不足している場合はfalseを返す', () => {
      process.env.LANGFUSE_ENABLED = 'true'
      delete process.env.LANGFUSE_SECRET_KEY
      delete process.env.LANGFUSE_PUBLIC_KEY
      clearEnvCache()

      expect(isLangfuseEnabled()).toBe(false)
    })
  })

  describe('validateRequiredKeys', () => {
    it('必要なキーが存在する場合は何も投げない', () => {
      process.env.QWEN_API_KEY = 'qwen-key'
      process.env.GEMINI_API_KEY = 'gemini-key'
      clearEnvCache()

      expect(() => validateRequiredKeys(['qwen', 'gemini'])).not.toThrow()
    })

    it('qwenキーが不足している場合はErrorを投げる', () => {
      delete process.env.QWEN_API_KEY
      clearEnvCache()

      expect(() => validateRequiredKeys(['qwen'])).toThrow(
        'Missing required environment variables: QWEN_API_KEY'
      )
    })

    it('geminiキーが不足している場合はErrorを投げる', () => {
      delete process.env.GEMINI_API_KEY
      clearEnvCache()

      expect(() => validateRequiredKeys(['gemini'])).toThrow(
        'Missing required environment variables: GEMINI_API_KEY'
      )
    })

    it('googleMapsキーが不足している場合はErrorを投げる', () => {
      delete process.env.GOOGLE_MAPS_API_KEY
      clearEnvCache()

      expect(() => validateRequiredKeys(['googleMaps'])).toThrow(
        'Missing required environment variables: GOOGLE_MAPS_API_KEY'
      )
    })

    it('複数キーが不足している場合は全て含むエラーを投げる', () => {
      delete process.env.QWEN_API_KEY
      delete process.env.GEMINI_API_KEY
      clearEnvCache()

      expect(() => validateRequiredKeys(['qwen', 'gemini'])).toThrow(
        'Missing required environment variables: QWEN_API_KEY, GEMINI_API_KEY'
      )
    })

    it('空配列の場合は何も投げない', () => {
      expect(() => validateRequiredKeys([])).not.toThrow()
    })
  })

  describe('clearEnvCache', () => {
    it('キャッシュがクリアされる', () => {
      process.env.QWEN_API_KEY = 'key-1'
      getEnv()

      clearEnvCache()
      process.env.QWEN_API_KEY = 'key-2'

      expect(getEnv().qwenApiKey).toBe('key-2')
    })
  })
})
