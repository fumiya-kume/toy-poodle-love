import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// RouteOptimizerPipelineをモック
const mockExecute = vi.fn()

vi.mock('../../src/pipeline/route-optimizer', () => ({
  RouteOptimizerPipeline: vi.fn().mockImplementation(() => ({
    execute: mockExecute,
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
  createPipelineTrace: vi.fn(() => ({
    trace: {
      update: mockTraceUpdate,
    },
    end: mockTraceEnd,
  })),
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

import { POST } from '@/app/api/pipeline/route-optimize/route'

describe('POST /api/pipeline/route-optimize', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    mockGetEnv.mockReturnValue({
      qwenApiKey: 'test-qwen-key',
      geminiApiKey: 'test-gemini-key',
      googleMapsApiKey: 'test-google-maps-key',
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

  const validBody = {
    startPoint: '東京駅',
    purpose: '観光',
    spotCount: 5,
    model: 'qwen',
  }

  describe('JSON解析', () => {
    it('無効なJSONで400エラー', async () => {
      const request = createInvalidJsonRequest()

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('Invalid JSON in request body')
    })
  })

  describe('バリデーション', () => {
    it('startPointがない場合は400エラー', async () => {
      const request = createRequest({
        purpose: '観光',
        spotCount: 5,
        model: 'qwen',
      })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('startPoint')
    })

    it('purposeがない場合は400エラー', async () => {
      const request = createRequest({
        startPoint: '東京駅',
        spotCount: 5,
        model: 'qwen',
      })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('purpose')
    })

    it('spotCountがない場合は400エラー', async () => {
      const request = createRequest({
        startPoint: '東京駅',
        purpose: '観光',
        model: 'qwen',
      })

      const response = await POST(request)

      expect(response.status).toBe(400)
    })

    it('spotCountが範囲外の場合は400エラー', async () => {
      const request = createRequest({
        ...validBody,
        spotCount: 2,
      })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('3 and 8')
    })

    it('modelが無効な場合は400エラー', async () => {
      const request = createRequest({
        ...validBody,
        model: 'invalid',
      })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('qwen')
    })
  })

  describe('APIキーチェック', () => {
    it('GoogleMapsキーがない場合はエラー', async () => {
      const mockErrorResponse = { _data: { error: 'No key' }, status: 500 }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'googleMaps') return mockErrorResponse
        return null
      })

      const request = createRequest(validBody)

      const response = await POST(request)

      expect(response).toBe(mockErrorResponse)
    })

    it('qwenモデルでQwenキーがない場合はエラー', async () => {
      const mockErrorResponse = { _data: { error: 'No key' }, status: 500 }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'qwen') return mockErrorResponse
        return null
      })

      const request = createRequest(validBody)

      const response = await POST(request)

      expect(response).toBe(mockErrorResponse)
    })

    it('geminiモデルでGeminiキーがない場合はエラー', async () => {
      const mockErrorResponse = { _data: { error: 'No key' }, status: 500 }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'gemini') return mockErrorResponse
        return null
      })

      const request = createRequest({ ...validBody, model: 'gemini' })

      const response = await POST(request)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('成功ケース', () => {
    it('正常にパイプライン結果を返す', async () => {
      const mockResult = {
        success: true,
        route: { routeName: 'テストルート', spots: [] },
        optimizedRoute: { totalDistanceMeters: 10000 },
        stats: { totalProcessingTimeMs: 5000 },
      }
      mockExecute.mockResolvedValue(mockResult)

      const request = createRequest(validBody)

      const response = await POST(request)

      expect(response.status).toBe(200)
      expect((response as any)._data).toEqual(mockResult)
    })

    it('RouteOptimizerPipelineを正しく呼び出す', async () => {
      mockExecute.mockResolvedValue({ success: true })

      const request = createRequest(validBody)

      await POST(request)

      expect(mockExecute).toHaveBeenCalledWith({
        startPoint: '東京駅',
        purpose: '観光',
        spotCount: 5,
        model: 'qwen',
      })
    })
  })

  describe('Langfuseトレース', () => {
    it('トレースが開始される', async () => {
      mockExecute.mockResolvedValue({ success: true })

      const request = createRequest(validBody)

      await POST(request)

      expect(mockTraceUpdate).toHaveBeenCalled()
    })

    it('トレースが正常終了する', async () => {
      const mockResult = { success: true }
      mockExecute.mockResolvedValue(mockResult)

      const request = createRequest(validBody)

      await POST(request)

      expect(mockTraceEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
        })
      )
    })
  })

  describe('エラーケース', () => {
    it('パイプラインエラー時は500エラー', async () => {
      mockExecute.mockRejectedValue(new Error('Pipeline failed'))

      const request = createRequest(validBody)

      const response = await POST(request)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Pipeline failed')
    })

    it('トレースにエラーを記録', async () => {
      mockExecute.mockRejectedValue(new Error('Test error'))

      const request = createRequest(validBody)

      await POST(request)

      expect(mockTraceEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Test error',
        })
      )
    })
  })
})
