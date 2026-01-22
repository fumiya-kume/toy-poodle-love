import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// ScenarioGeneratorをモック
const mockGenerateSingleSpot = vi.fn()

vi.mock('../../src/scenario/generator', () => ({
  ScenarioGenerator: vi.fn().mockImplementation(() => ({
    generateSingleSpot: mockGenerateSingleSpot,
  })),
}))

// NextResponseをモック
vi.mock('next/server', () => ({
  NextRequest: vi.fn(),
  NextResponse: {
    json: vi.fn((data, init) => ({
      _data: data,
      status: init?.status || 200,
      json: async () => data,
    })),
  },
}))

import { POST } from '@/app/api/scenario/spot/route'

describe('POST /api/scenario/spot', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>
  let originalEnv: NodeJS.ProcessEnv

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    originalEnv = { ...process.env }

    // デフォルトの環境変数
    process.env.QWEN_API_KEY = 'test-qwen-key'
    process.env.GEMINI_API_KEY = 'test-gemini-key'
    process.env.QWEN_REGION = 'international'
  })

  afterEach(() => {
    consoleErrorSpy.mockRestore()
    process.env = originalEnv
  })

  function createRequest(body: Record<string, unknown>) {
    return {
      json: vi.fn().mockResolvedValue(body),
    } as unknown as Request
  }

  describe('バリデーション', () => {
    it('routeNameがない場合は400エラー', async () => {
      const request = createRequest({ spotName: 'スポット1' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('routeNameとspotNameが必要です')
    })

    it('spotNameがない場合は400エラー', async () => {
      const request = createRequest({ routeName: 'テストルート' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('routeNameとspotNameが必要です')
    })
  })

  describe('APIキーチェック', () => {
    it('qwenモデルでAPIキーがない場合はエラー', async () => {
      delete process.env.QWEN_API_KEY

      const request = createRequest({
        routeName: 'ルート',
        spotName: 'スポット',
        models: 'qwen',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('QWEN_API_KEYが設定されていません')
    })

    it('geminiモデルでAPIキーがない場合はエラー', async () => {
      delete process.env.GEMINI_API_KEY

      const request = createRequest({
        routeName: 'ルート',
        spotName: 'スポット',
        models: 'gemini',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('GEMINI_API_KEYが設定されていません')
    })

    it('bothモデルでQwenキーがない場合はエラー', async () => {
      delete process.env.QWEN_API_KEY

      const request = createRequest({
        routeName: 'ルート',
        spotName: 'スポット',
        models: 'both',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
    })

    it('bothモデルでGeminiキーがない場合はエラー', async () => {
      delete process.env.GEMINI_API_KEY

      const request = createRequest({
        routeName: 'ルート',
        spotName: 'スポット',
        models: 'both',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
    })
  })

  describe('成功ケース', () => {
    it('正常にシナリオを返す', async () => {
      const mockScenario = {
        name: 'スポット1',
        qwen: 'Qwenシナリオ',
        gemini: 'Geminiシナリオ',
      }
      mockGenerateSingleSpot.mockResolvedValue(mockScenario)

      const request = createRequest({
        routeName: 'テストルート',
        spotName: 'スポット1',
        description: '説明文',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.scenario).toEqual(mockScenario)
    })

    it('ScenarioGeneratorを正しく呼び出す', async () => {
      mockGenerateSingleSpot.mockResolvedValue({})

      const request = createRequest({
        routeName: 'テストルート',
        spotName: 'スポット1',
        description: '説明',
        point: '東京都渋谷区',
        models: 'qwen',
      })

      await POST(request as any)

      expect(mockGenerateSingleSpot).toHaveBeenCalledWith(
        'テストルート',
        'スポット1',
        '説明',
        '東京都渋谷区',
        'qwen'
      )
    })

    it('デフォルトでbothモデルを使用', async () => {
      mockGenerateSingleSpot.mockResolvedValue({})

      const request = createRequest({
        routeName: 'ルート',
        spotName: 'スポット',
      })

      await POST(request as any)

      expect(mockGenerateSingleSpot).toHaveBeenCalledWith(
        'ルート',
        'スポット',
        undefined,
        undefined,
        'both'
      )
    })
  })

  describe('エラーケース', () => {
    it('生成エラー時は500エラー', async () => {
      mockGenerateSingleSpot.mockRejectedValue(new Error('Generation failed'))

      const request = createRequest({
        routeName: 'ルート',
        spotName: 'スポット',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Generation failed')
    })
  })
})
