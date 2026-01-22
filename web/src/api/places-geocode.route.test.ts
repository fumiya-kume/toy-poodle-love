import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// GooglePlacesClientをモック
const mockGeocodeBatch = vi.fn()

vi.mock('../../src/google-places-client', () => ({
  GooglePlacesClient: vi.fn().mockImplementation(() => ({
    geocodeBatch: mockGeocodeBatch,
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

import { POST } from '@/app/api/places/geocode/route'

describe('POST /api/places/geocode', () => {
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

  describe('バリデーション', () => {
    it('addressesがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('addresses配列が必要です')
      expect((response as any)._data.success).toBe(false)
    })

    it('addressesが配列でない場合は400エラー', async () => {
      const request = createRequest({ addresses: 'not-an-array' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('addresses配列が必要です')
    })

    it('addressesが空配列の場合は400エラー', async () => {
      const request = createRequest({ addresses: [] })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('addresses配列が必要です')
    })
  })

  describe('APIキーチェック', () => {
    it('APIキーがない場合はエラーレスポンスを返す', async () => {
      const mockErrorResponse = {
        _data: { error: 'GOOGLE_MAPS_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockReturnValue(mockErrorResponse)

      const request = createRequest({ addresses: ['東京駅'] })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('成功ケース', () => {
    it('正常にジオコーディング結果を返す', async () => {
      const mockPlaces = [
        {
          placeId: 'place-id-1',
          location: { latitude: 35.6812, longitude: 139.7671 },
          formattedAddress: '東京都千代田区丸の内1丁目',
        },
      ]
      mockGeocodeBatch.mockResolvedValue(mockPlaces)

      const request = createRequest({ addresses: ['東京駅'] })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.places).toEqual(mockPlaces)
    })

    it('複数のアドレスをバッチ処理する', async () => {
      mockGeocodeBatch.mockResolvedValue([])

      const request = createRequest({
        addresses: ['東京駅', '渋谷駅', '新宿駅'],
      })

      await POST(request as any)

      expect(mockGeocodeBatch).toHaveBeenCalledWith([
        '東京駅',
        '渋谷駅',
        '新宿駅',
      ])
    })
  })

  describe('エラーケース', () => {
    it('APIエラー時は500エラー', async () => {
      mockGeocodeBatch.mockRejectedValue(new Error('Geocoding failed'))

      const request = createRequest({ addresses: ['東京駅'] })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.success).toBe(false)
      expect((response as any)._data.error).toBe('Geocoding failed')
    })

    it('エラーメッセージがない場合はデフォルトメッセージを返す', async () => {
      mockGeocodeBatch.mockRejectedValue({})

      const request = createRequest({ addresses: ['東京駅'] })

      const response = await POST(request as any)

      expect((response as any)._data.error).toBe('ジオコーディングに失敗しました')
    })
  })
})
