import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { requireApiKey, requireApiKeys } from './api-helpers'

// envモジュールをモック
vi.mock('./env', () => ({
  hasQwenApiKey: vi.fn(),
  hasGeminiApiKey: vi.fn(),
  hasGoogleMapsApiKey: vi.fn(),
}))

// NextResponseをモック
vi.mock('next/server', () => ({
  NextResponse: {
    json: vi.fn((data, init) => ({
      _data: data,
      status: init?.status || 200,
      json: async () => data,
    })),
  },
}))

describe('api-helpers', () => {
  let mockHasQwenApiKey: ReturnType<typeof vi.fn>
  let mockHasGeminiApiKey: ReturnType<typeof vi.fn>
  let mockHasGoogleMapsApiKey: ReturnType<typeof vi.fn>

  beforeEach(async () => {
    vi.clearAllMocks()
    const envModule = await import('./env')
    mockHasQwenApiKey = vi.mocked(envModule.hasQwenApiKey)
    mockHasGeminiApiKey = vi.mocked(envModule.hasGeminiApiKey)
    mockHasGoogleMapsApiKey = vi.mocked(envModule.hasGoogleMapsApiKey)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('requireApiKey', () => {
    describe('qwen', () => {
      it('qwenキーが存在する場合はnullを返す', () => {
        mockHasQwenApiKey.mockReturnValue(true)

        const result = requireApiKey('qwen')

        expect(result).toBeNull()
      })

      it('qwenキーが不足時はNextResponseエラーを返す', () => {
        mockHasQwenApiKey.mockReturnValue(false)

        const result = requireApiKey('qwen')

        expect(result).not.toBeNull()
        expect(result?.status).toBe(500)
        expect((result as unknown as { _data: { error: string } })._data.error).toBe(
          'QWEN_API_KEY is not configured'
        )
      })
    })

    describe('gemini', () => {
      it('geminiキーが存在する場合はnullを返す', () => {
        mockHasGeminiApiKey.mockReturnValue(true)

        const result = requireApiKey('gemini')

        expect(result).toBeNull()
      })

      it('geminiキーが不足時はNextResponseエラーを返す', () => {
        mockHasGeminiApiKey.mockReturnValue(false)

        const result = requireApiKey('gemini')

        expect(result).not.toBeNull()
        expect(result?.status).toBe(500)
        expect((result as unknown as { _data: { error: string } })._data.error).toBe(
          'GEMINI_API_KEY is not configured'
        )
      })
    })

    describe('googleMaps', () => {
      it('googleMapsキーが存在する場合はnullを返す', () => {
        mockHasGoogleMapsApiKey.mockReturnValue(true)

        const result = requireApiKey('googleMaps')

        expect(result).toBeNull()
      })

      it('googleMapsキーが不足時はNextResponseエラーを返す', () => {
        mockHasGoogleMapsApiKey.mockReturnValue(false)

        const result = requireApiKey('googleMaps')

        expect(result).not.toBeNull()
        expect(result?.status).toBe(500)
        expect((result as unknown as { _data: { error: string } })._data.error).toBe(
          'GOOGLE_MAPS_API_KEY is not configured'
        )
      })
    })
  })

  describe('requireApiKeys', () => {
    it('複数キーが全て存在する場合はnullを返す', () => {
      mockHasQwenApiKey.mockReturnValue(true)
      mockHasGeminiApiKey.mockReturnValue(true)

      const result = requireApiKeys(['qwen', 'gemini'])

      expect(result).toBeNull()
    })

    it('一つでも不足があればエラーを返す', () => {
      mockHasQwenApiKey.mockReturnValue(true)
      mockHasGeminiApiKey.mockReturnValue(false)

      const result = requireApiKeys(['qwen', 'gemini'])

      expect(result).not.toBeNull()
      expect((result as unknown as { _data: { error: string } })._data.error).toBe(
        'GEMINI_API_KEY is not configured'
      )
    })

    it('空配列の場合はnullを返す', () => {
      const result = requireApiKeys([])

      expect(result).toBeNull()
    })

    it('最初に見つかった不足キーのエラーを返す', () => {
      mockHasQwenApiKey.mockReturnValue(false)
      mockHasGeminiApiKey.mockReturnValue(false)

      const result = requireApiKeys(['qwen', 'gemini'])

      expect(result).not.toBeNull()
      expect((result as unknown as { _data: { error: string } })._data.error).toBe(
        'QWEN_API_KEY is not configured'
      )
    })

    it('順序を変えると最初の不足キーが変わる', () => {
      mockHasQwenApiKey.mockReturnValue(false)
      mockHasGeminiApiKey.mockReturnValue(false)

      const result = requireApiKeys(['gemini', 'qwen'])

      expect((result as unknown as { _data: { error: string } })._data.error).toBe(
        'GEMINI_API_KEY is not configured'
      )
    })
  })
})
