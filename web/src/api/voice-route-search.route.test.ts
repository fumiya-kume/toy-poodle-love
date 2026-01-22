import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// LocationExtractorをモック
const mockExtract = vi.fn()

vi.mock('../../src/location-extractor', () => ({
  LocationExtractor: vi.fn().mockImplementation(() => ({
    extract: mockExtract,
  })),
}))

// GooglePlacesClientをモック
const mockGeocode = vi.fn()
const mockGeocodeBatch = vi.fn()

vi.mock('../../src/google-places-client', () => ({
  GooglePlacesClient: vi.fn().mockImplementation(() => ({
    geocode: mockGeocode,
    geocodeBatch: mockGeocodeBatch,
  })),
}))

// GoogleRoutesClientをモック
const mockOptimizeRoute = vi.fn()

vi.mock('../../src/google-routes-client', () => ({
  GoogleRoutesClient: vi.fn().mockImplementation(() => ({
    optimizeRoute: mockOptimizeRoute,
  })),
}))

// configをモック
const mockGetEnv = vi.fn()

vi.mock('../../src/config', () => ({
  getEnv: () => mockGetEnv(),
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

import { POST } from '@/app/api/voice-route/search/route'

describe('POST /api/voice-route/search', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    mockGetEnv.mockReturnValue({
      googleMapsApiKey: 'test-google-maps-key',
    })
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  function createRequest(body: Record<string, unknown>) {
    return {
      json: vi.fn().mockResolvedValue(body),
    } as unknown as Request
  }

  describe('バリデーション', () => {
    it('textがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('テキストが必要です')
    })

    it('textが空の場合は400エラー', async () => {
      const request = createRequest({ text: '   ' })

      const response = await POST(request)

      expect(response.status).toBe(400)
    })

    it('無効なmodelで400エラー', async () => {
      const request = createRequest({ text: 'test', model: 'invalid' })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('qwen')
    })
  })

  describe('Step1: 地点抽出', () => {
    it('LocationExtractorを呼び出す', async () => {
      mockExtract.mockResolvedValue({
        origin: '東京駅',
        destination: '渋谷駅',
        waypoints: [],
        confidence: 0.9,
      })
      mockGeocode.mockResolvedValue({
        placeId: 'test-id',
        location: { latitude: 35.68, longitude: 139.76 },
        formattedAddress: '東京駅',
      })
      mockOptimizeRoute.mockResolvedValue({
        totalDistanceMeters: 5000,
        totalDurationSeconds: 1500,
        legs: [],
      })

      const request = createRequest({ text: '東京駅から渋谷駅まで' })

      await POST(request)

      expect(mockExtract).toHaveBeenCalled()
    })

    it('出発地も目的地もない場合はエラー', async () => {
      mockExtract.mockResolvedValue({
        origin: null,
        destination: null,
        waypoints: [],
        confidence: 0.1,
      })

      const request = createRequest({ text: 'どこかに行きたい' })

      const response = await POST(request)

      expect((response as any)._data.success).toBe(false)
      expect((response as any)._data.error).toContain('出発地または目的地を特定できませんでした')
    })
  })

  describe('Step2: ジオコーディング', () => {
    it('GoogleMapsAPIキーがない場合はエラー', async () => {
      mockGetEnv.mockReturnValue({ googleMapsApiKey: undefined })
      mockExtract.mockResolvedValue({
        origin: '東京駅',
        destination: null,
        waypoints: [],
      })

      const request = createRequest({ text: '東京駅から' })

      const response = await POST(request)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Google APIキーが設定されていません')
    })

    it('出発地をジオコード', async () => {
      mockExtract.mockResolvedValue({
        origin: '東京駅',
        destination: null,
        waypoints: [],
      })
      mockGeocode.mockResolvedValue({
        placeId: 'origin-id',
        location: { latitude: 35.68, longitude: 139.76 },
        formattedAddress: '東京駅',
      })

      const request = createRequest({ text: '東京駅から' })

      const response = await POST(request)

      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.geocodedPlaces.origin).toBeDefined()
    })

    it('ジオコード失敗でも継続', async () => {
      mockExtract.mockResolvedValue({
        origin: '不明な場所',
        destination: '渋谷駅',
        waypoints: [],
      })
      mockGeocode.mockImplementation((address: string) => {
        if (address === '不明な場所') {
          throw new Error('Geocode failed')
        }
        return {
          placeId: 'dest-id',
          location: { latitude: 35.65, longitude: 139.70 },
          formattedAddress: '渋谷駅',
        }
      })

      const request = createRequest({ text: '不明な場所から渋谷駅まで' })

      const response = await POST(request)

      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.geocodedPlaces.destination).toBeDefined()
    })
  })

  describe('Step3: ルート検索', () => {
    it('両方ある場合にルート検索実行', async () => {
      mockExtract.mockResolvedValue({
        origin: '東京駅',
        destination: '渋谷駅',
        waypoints: [],
      })
      mockGeocode.mockResolvedValue({
        placeId: 'test-id',
        location: { latitude: 35.68, longitude: 139.76 },
        formattedAddress: '住所',
      })
      mockOptimizeRoute.mockResolvedValue({
        totalDistanceMeters: 10000,
        totalDurationSeconds: 2000,
        legs: [{ distanceMeters: 10000, duration: '2000s' }],
      })

      const request = createRequest({ text: '東京駅から渋谷駅まで' })

      const response = await POST(request)

      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.route).toBeDefined()
      expect((response as any)._data.route.totalDistanceMeters).toBe(10000)
    })

    it('ルート検索失敗でも部分結果を返す', async () => {
      mockExtract.mockResolvedValue({
        origin: '東京駅',
        destination: '渋谷駅',
        waypoints: [],
      })
      mockGeocode.mockResolvedValue({
        placeId: 'test-id',
        location: { latitude: 35.68, longitude: 139.76 },
        formattedAddress: '住所',
      })
      mockOptimizeRoute.mockRejectedValue(new Error('Route search failed'))

      const request = createRequest({ text: '東京駅から渋谷駅まで' })

      const response = await POST(request)

      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.geocodedPlaces).toBeDefined()
      expect((response as any)._data.error).toContain('ルート検索に失敗しました')
    })
  })

  describe('部分成功', () => {
    it('出発地のみの場合', async () => {
      mockExtract.mockResolvedValue({
        origin: '東京駅',
        destination: null,
        waypoints: [],
      })
      mockGeocode.mockResolvedValue({
        placeId: 'origin-id',
        location: { latitude: 35.68, longitude: 139.76 },
        formattedAddress: '東京駅',
      })

      const request = createRequest({ text: '東京駅から' })

      const response = await POST(request)

      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.route).toBeUndefined()
    })
  })

  describe('エラーケース', () => {
    it('予期しないエラーで500', async () => {
      mockExtract.mockRejectedValue(new Error('Unexpected error'))

      const request = createRequest({ text: 'テスト' })

      const response = await POST(request)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Unexpected error')
    })
  })
})
