import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// ScenarioGeneratorをモック
const mockGenerateRoute = vi.fn()

vi.mock('../../src/scenario/generator', () => ({
  ScenarioGenerator: vi.fn().mockImplementation(() => ({
    generateRoute: mockGenerateRoute,
  })),
}))

// configをモック
const mockGetEnv = vi.fn()
const mockRequireApiKey = vi.fn()

vi.mock('../../src/config', () => ({
  getEnv: () => mockGetEnv(),
  requireApiKey: (keyType: string) => mockRequireApiKey(keyType),
}))

// langfuse-clientをモック
const mockTraceEnd = vi.fn().mockResolvedValue(undefined)
const mockTraceUpdate = vi.fn()

vi.mock('../../src/langfuse-client', () => ({
  createScenarioTrace: vi.fn(() => ({
    trace: {
      update: mockTraceUpdate,
    },
    end: mockTraceEnd,
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

import { POST } from '@/app/api/scenario/route'

describe('POST /api/scenario', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // デフォルト設定
    mockGetEnv.mockReturnValue({
      qwenApiKey: 'test-qwen-key',
      geminiApiKey: 'test-gemini-key',
      qwenRegion: 'international',
    })
    mockRequireApiKey.mockReturnValue(null)
  })

  afterEach(() => {
    consoleErrorSpy.mockRestore()
  })

  function createRequest(body: Record<string, unknown>) {
    return {
      json: vi.fn().mockResolvedValue(body),
    } as unknown as Request
  }

  function createInvalidJsonRequest() {
    return {
      json: vi.fn().mockRejectedValue(new Error('Invalid JSON')),
    } as unknown as Request
  }

  const validRoute = {
    routeName: 'テストルート',
    spots: [
      { name: 'スポット1', location: { lat: 35.68, lng: 139.76 } },
      { name: 'スポット2', location: { lat: 35.65, lng: 139.69 } },
    ],
  }

  describe('JSON解析', () => {
    it('無効なJSONで400エラー', async () => {
      const request = createInvalidJsonRequest()

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('Invalid JSON in request body')
    })
  })

  describe('バリデーション', () => {
    it('routeがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('ルート情報が不正です')
    })

    it('routeNameがない場合は400エラー', async () => {
      const request = createRequest({
        route: { spots: [] },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('routeNameとspotsが必要です')
    })

    it('spotsがない場合は400エラー', async () => {
      const request = createRequest({
        route: { routeName: 'Test' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })
  })

  describe('APIキーチェック', () => {
    it('qwenモデルでAPIキーがない場合はエラー', async () => {
      const mockErrorResponse = {
        _data: { error: 'QWEN_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'qwen') return mockErrorResponse
        return null
      })

      const request = createRequest({
        route: validRoute,
        models: 'qwen',
      })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })

    it('geminiモデルでAPIキーがない場合はエラー', async () => {
      const mockErrorResponse = {
        _data: { error: 'GEMINI_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'gemini') return mockErrorResponse
        return null
      })

      const request = createRequest({
        route: validRoute,
        models: 'gemini',
      })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })

    it('bothモデルで両方必要', async () => {
      const mockErrorResponse = {
        _data: { error: 'QWEN_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'qwen') return mockErrorResponse
        return null
      })

      const request = createRequest({
        route: validRoute,
        models: 'both',
      })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('成功ケース', () => {
    it('qwenモデルで生成', async () => {
      const mockResult = {
        routeName: 'テストルート',
        spots: [],
        stats: {
          totalSpots: 2,
          successCount: 2,
          processingTimeMs: 100,
        },
      }
      mockGenerateRoute.mockResolvedValue(mockResult)

      const request = createRequest({
        route: validRoute,
        models: 'qwen',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.data).toEqual(mockResult)
    })

    it('geminiモデルで生成', async () => {
      const mockResult = {
        routeName: 'テストルート',
        spots: [],
        stats: { totalSpots: 2, successCount: 2, processingTimeMs: 150 },
      }
      mockGenerateRoute.mockResolvedValue(mockResult)

      const request = createRequest({
        route: validRoute,
        models: 'gemini',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
    })

    it('bothモデルで生成', async () => {
      const mockResult = {
        routeName: 'テストルート',
        spots: [],
        stats: { totalSpots: 2, successCount: 2, processingTimeMs: 200 },
      }
      mockGenerateRoute.mockResolvedValue(mockResult)

      const request = createRequest({
        route: validRoute,
        models: 'both',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
    })

    it('デフォルトでbothモデルを使用', async () => {
      mockGenerateRoute.mockResolvedValue({
        routeName: 'Test',
        spots: [],
        stats: { totalSpots: 0, successCount: 0, processingTimeMs: 0 },
      })

      const request = createRequest({
        route: validRoute,
      })

      await POST(request as any)

      expect(mockGenerateRoute).toHaveBeenCalledWith(validRoute, 'both', false)
    })
  })

  describe('Langfuseトレース', () => {
    it('トレースが開始される', async () => {
      mockGenerateRoute.mockResolvedValue({
        routeName: 'Test',
        spots: [],
        stats: { totalSpots: 0, successCount: 0, processingTimeMs: 0 },
      })

      const request = createRequest({
        route: validRoute,
      })

      await POST(request as any)

      expect(mockTraceUpdate).toHaveBeenCalled()
    })

    it('トレースが正常終了する', async () => {
      mockGenerateRoute.mockResolvedValue({
        routeName: 'Test',
        spots: [],
        stats: { totalSpots: 2, successCount: 2, processingTimeMs: 100 },
      })

      const request = createRequest({
        route: validRoute,
      })

      await POST(request as any)

      expect(mockTraceEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
        })
      )
    })
  })

  describe('エラーケース', () => {
    it('生成エラー時は500エラー', async () => {
      mockGenerateRoute.mockRejectedValue(new Error('Generation failed'))

      const request = createRequest({
        route: validRoute,
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.success).toBe(false)
      expect((response as any)._data.error).toBe('Generation failed')
    })

    it('トレースにエラーを記録', async () => {
      mockGenerateRoute.mockRejectedValue(new Error('Test error'))

      const request = createRequest({
        route: validRoute,
      })

      await POST(request as any)

      expect(mockTraceEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Test error',
        })
      )
    })
  })
})
