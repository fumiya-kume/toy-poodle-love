import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// GoogleRoutesClientをモック
const mockOptimizeRoute = vi.fn()

vi.mock('../../src/google-routes-client', () => ({
  GoogleRoutesClient: vi.fn().mockImplementation(() => ({
    optimizeRoute: mockOptimizeRoute,
  })),
}))

// configをモック
const mockGetEnv = vi.fn()
const mockRequireApiKey = vi.fn()

vi.mock('../../src/config', () => ({
  getEnv: () => mockGetEnv(),
  requireApiKey: (keyType: string) => mockRequireApiKey(keyType),
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

import { POST } from '@/app/api/routes/optimize/route'

describe('POST /api/routes/optimize', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // デフォルト設定
    mockGetEnv.mockReturnValue({
      googleMapsApiKey: 'test-google-maps-key',
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

  const validOrigin = {
    location: { latitude: 35.68, longitude: 139.76 },
  }
  const validDestination = {
    location: { latitude: 35.65, longitude: 139.69 },
  }
  const validIntermediates = [
    { location: { latitude: 35.66, longitude: 139.70 } },
  ]

  describe('バリデーション', () => {
    it('originがない場合は400エラー', async () => {
      const request = createRequest({
        destination: validDestination,
        intermediates: validIntermediates,
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('出発地点（origin）が必要です')
    })

    it('destinationがない場合は400エラー', async () => {
      const request = createRequest({
        origin: validOrigin,
        intermediates: validIntermediates,
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('目的地（destination）が必要です')
    })

    it('intermediatesがない場合は400エラー', async () => {
      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('経由地点（intermediates）配列が必要です')
    })

    it('intermediatesが配列でない場合は400エラー', async () => {
      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
        intermediates: 'not-an-array',
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('経由地点（intermediates）配列が必要です')
    })
  })

  describe('APIキーチェック', () => {
    it('APIキーがない場合はエラーレスポンスを返す', async () => {
      const mockErrorResponse = {
        _data: { error: 'GOOGLE_MAPS_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockReturnValue(mockErrorResponse)

      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
        intermediates: validIntermediates,
      })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('成功ケース', () => {
    it('正常に最適化結果を返す', async () => {
      const mockOptimizedRoute = {
        totalDistanceMeters: 5000,
        totalDurationSeconds: 1500,
        optimizedIntermediateWaypointIndex: [0],
        legs: [],
      }
      mockOptimizeRoute.mockResolvedValue(mockOptimizedRoute)

      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
        intermediates: validIntermediates,
      })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.optimizedRoute).toEqual(mockOptimizedRoute)
    })

    it('GoogleRoutesClientを正しく呼び出す', async () => {
      mockOptimizeRoute.mockResolvedValue({})

      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
        intermediates: validIntermediates,
        travelMode: 'DRIVE',
        optimizeWaypointOrder: true,
      })

      await POST(request as any)

      expect(mockOptimizeRoute).toHaveBeenCalledWith({
        origin: validOrigin,
        destination: validDestination,
        intermediates: validIntermediates,
        travelMode: 'DRIVE',
        optimizeWaypointOrder: true,
      })
    })
  })

  describe('エラーケース', () => {
    it('APIエラー時は500エラー', async () => {
      mockOptimizeRoute.mockRejectedValue(new Error('Route optimization failed'))

      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
        intermediates: validIntermediates,
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.success).toBe(false)
      expect((response as any)._data.error).toBe('Route optimization failed')
    })

    it('エラーメッセージがない場合はデフォルトメッセージを返す', async () => {
      mockOptimizeRoute.mockRejectedValue({})

      const request = createRequest({
        origin: validOrigin,
        destination: validDestination,
        intermediates: validIntermediates,
      })

      const response = await POST(request as any)

      expect((response as any)._data.error).toBe('ルート最適化に失敗しました')
    })
  })
})
