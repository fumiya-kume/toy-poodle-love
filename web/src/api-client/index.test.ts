import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { TaxiScenarioApiClient, ApiClientConfig } from './index'

// fetchをモック
const mockFetch = vi.fn()
vi.stubGlobal('fetch', mockFetch)

describe('TaxiScenarioApiClient', () => {
  let client: TaxiScenarioApiClient

  beforeEach(() => {
    vi.clearAllMocks()
    client = new TaxiScenarioApiClient()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('constructor', () => {
    it('デフォルト値を使用する', () => {
      const defaultClient = new TaxiScenarioApiClient()
      expect(defaultClient).toBeInstanceOf(TaxiScenarioApiClient)
    })

    it('カスタムbaseUrlを受け入れる', async () => {
      const customClient = new TaxiScenarioApiClient({
        baseUrl: 'https://api.example.com',
      })
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ response: 'test' }),
      })

      await customClient.qwenChat('test')

      expect(mockFetch).toHaveBeenCalledWith(
        'https://api.example.com/api/qwen',
        expect.any(Object)
      )
    })

    it('カスタムtimeoutを受け入れる', async () => {
      // 短いタイムアウト（100ms）でテスト
      const customClient = new TaxiScenarioApiClient({ timeout: 100 })

      // AbortErrorをシミュレートするモック
      mockFetch.mockImplementation((url: string, options: RequestInit) => {
        return new Promise((resolve, reject) => {
          const checkAbort = () => {
            if (options.signal?.aborted) {
              const error = new Error('The operation was aborted')
              error.name = 'AbortError'
              reject(error)
            }
          }
          // abortイベントをリッスン
          options.signal?.addEventListener('abort', checkAbort)
        })
      })

      await expect(customClient.qwenChat('test')).rejects.toThrow(
        'リクエストがタイムアウトしました'
      )
    })
  })

  describe('request (HTTPリクエスト共通処理)', () => {
    it('Content-Typeヘッダーをapplication/jsonに設定する', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ response: 'test' }),
      })

      await client.qwenChat('test')

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
        })
      )
    })

    it('非2xxレスポンスでエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        json: () => Promise.resolve({ error: 'サーバーエラー' }),
      })

      await expect(client.qwenChat('test')).rejects.toThrow('サーバーエラー')
    })

    it('非2xxレスポンスでJSONパースに失敗した場合はHTTPステータスを返す', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        json: () => Promise.reject(new Error('Invalid JSON')),
      })

      await expect(client.qwenChat('test')).rejects.toThrow(
        'HTTP 500: Internal Server Error'
      )
    })

    it('タイムアウト時に日本語エラーメッセージをスローする', async () => {
      // 短いタイムアウトでテスト
      const shortTimeoutClient = new TaxiScenarioApiClient({ timeout: 100 })

      // AbortErrorをシミュレートするモック
      mockFetch.mockImplementation((url: string, options: RequestInit) => {
        return new Promise((resolve, reject) => {
          const checkAbort = () => {
            if (options.signal?.aborted) {
              const error = new Error('The operation was aborted')
              error.name = 'AbortError'
              reject(error)
            }
          }
          options.signal?.addEventListener('abort', checkAbort)
        })
      })

      await expect(shortTimeoutClient.qwenChat('test')).rejects.toThrow(
        'リクエストがタイムアウトしました'
      )
    })

    it('ネットワークエラーをそのままスローする', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'))

      await expect(client.qwenChat('test')).rejects.toThrow('Network error')
    })
  })

  describe('qwenChat', () => {
    it('正常なレスポンスの場合はテキストを返す', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ response: 'Hello from Qwen!' }),
      })

      const result = await client.qwenChat('Say hello')
      expect(result).toBe('Hello from Qwen!')
    })

    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ response: 'test' }),
      })

      await client.qwenChat('Test message')

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/qwen',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({ message: 'Test message' }),
        })
      )
    })
  })

  describe('geminiChat', () => {
    it('正常なレスポンスの場合はテキストを返す', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ response: 'Hello from Gemini!' }),
      })

      const result = await client.geminiChat('Say hello')
      expect(result).toBe('Hello from Gemini!')
    })

    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ response: 'test' }),
      })

      await client.geminiChat('Test message')

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/gemini',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({ message: 'Test message' }),
        })
      )
    })
  })

  describe('geocode', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            places: [
              { placeId: 'place1', inputAddress: '東京駅' },
              { placeId: 'place2', inputAddress: '渋谷駅' },
            ],
          }),
      })

      await client.geocode({ addresses: ['東京駅', '渋谷駅'] })

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/places/geocode',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({ addresses: ['東京駅', '渋谷駅'] }),
        })
      )
    })

    it('GeocodeResponseを返す', async () => {
      const expectedResponse = {
        success: true,
        places: [
          { placeId: 'place1', inputAddress: '東京駅', lat: 35.681, lng: 139.767 },
        ],
      }
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(expectedResponse),
      })

      const result = await client.geocode({ addresses: ['東京駅'] })

      expect(result).toEqual(expectedResponse)
    })
  })

  describe('optimizeRoute', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            optimizedWaypoints: [],
          }),
      })

      const request = {
        origin: { placeId: 'origin1', name: '出発地' },
        destination: { placeId: 'dest1', name: '目的地' },
        intermediates: [],
        travelMode: 'DRIVE' as const,
        optimizeWaypointOrder: true,
      }

      await client.optimizeRoute(request)

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/routes/optimize',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(request),
        })
      )
    })
  })

  describe('pipelineRouteOptimize', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      const request = {
        startPoint: '東京駅',
        purpose: '観光',
        spotCount: 5,
        model: 'qwen' as const,
      }

      await client.pipelineRouteOptimize(request)

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/pipeline/route-optimize',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(request),
        })
      )
    })
  })

  describe('generateRoute', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true, spots: [] }),
      })

      const request = {
        input: {
          startPoint: '東京駅',
          purpose: '観光',
          spotCount: 5,
          model: 'qwen' as const,
        },
      }

      await client.generateRoute(request)

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/route/generate',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(request),
        })
      )
    })
  })

  describe('generateScenario', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true, scenario: 'test' }),
      })

      const request = {
        route: {
          routeName: 'テストルート',
          spots: [
            { name: '東京駅', type: 'start' as const },
            { name: '新宿駅', type: 'waypoint' as const },
            { name: '渋谷駅', type: 'destination' as const },
          ],
        },
        models: 'qwen' as const,
      }

      await client.generateScenario(request)

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/scenario',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(request),
        })
      )
    })
  })

  describe('generateSpotScenario', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      const request = {
        routeName: 'テストルート',
        spotName: '東京スカイツリー',
        description: '観光案内',
        models: 'qwen' as const,
      }

      await client.generateSpotScenario(request)

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/scenario/spot',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(request),
        })
      )
    })
  })

  describe('integrateScenario', () => {
    it('正しいエンドポイントとボディでリクエストする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      const request = {
        integration: {
          routeName: 'テストルート',
          spots: [
            { name: 'スポット1', type: 'waypoint' as const, qwen: 'シナリオ1' },
          ],
          sourceModel: 'qwen' as const,
        },
      }

      await client.integrateScenario(request)

      expect(mockFetch).toHaveBeenCalledWith(
        '/api/scenario/integrate',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(request),
        })
      )
    })
  })

  describe('optimizeRouteFromAddresses', () => {
    it('住所が2つ未満の場合はエラーをスローする', async () => {
      await expect(client.optimizeRouteFromAddresses(['東京駅'])).rejects.toThrow(
        '最低2つの住所が必要です'
      )
    })

    it('空の配列の場合はエラーをスローする', async () => {
      await expect(client.optimizeRouteFromAddresses([])).rejects.toThrow(
        '最低2つの住所が必要です'
      )
    })

    it('ジオコーディングに失敗した場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: false,
            error: 'ジオコーディングエラー',
          }),
      })

      await expect(
        client.optimizeRouteFromAddresses(['東京駅', '渋谷駅'])
      ).rejects.toThrow('ジオコーディングエラー')
    })

    it('ジオコーディング結果がnullの場合はデフォルトエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: false,
            places: null,
          }),
      })

      await expect(
        client.optimizeRouteFromAddresses(['東京駅', '渋谷駅'])
      ).rejects.toThrow('ジオコーディングに失敗しました')
    })

    it('有効な地点が2つ未満の場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            places: [{ placeId: 'place1', inputAddress: '東京駅' }],
          }),
      })

      await expect(
        client.optimizeRouteFromAddresses(['東京駅', '不明な場所'])
      ).rejects.toThrow('有効な地点が2つ以上見つかりませんでした')
    })

    it('ジオコーディングとルート最適化を連鎖させる', async () => {
      // ジオコーディングのモック
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            places: [
              { placeId: 'place1', inputAddress: '東京駅' },
              { placeId: 'place2', inputAddress: '渋谷駅' },
            ],
          }),
      })

      // ルート最適化のモック
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            optimizedWaypoints: [],
          }),
      })

      await client.optimizeRouteFromAddresses(['東京駅', '渋谷駅'])

      expect(mockFetch).toHaveBeenCalledTimes(2)
      expect(mockFetch).toHaveBeenNthCalledWith(
        1,
        '/api/places/geocode',
        expect.any(Object)
      )
      expect(mockFetch).toHaveBeenNthCalledWith(
        2,
        '/api/routes/optimize',
        expect.any(Object)
      )
    })

    it('origin、destination、intermediatesを正しくマッピングする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            places: [
              { placeId: 'origin', inputAddress: '東京駅' },
              { placeId: 'mid1', inputAddress: '新宿駅' },
              { placeId: 'mid2', inputAddress: '池袋駅' },
              { placeId: 'dest', inputAddress: '渋谷駅' },
            ],
          }),
      })

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      await client.optimizeRouteFromAddresses([
        '東京駅',
        '新宿駅',
        '池袋駅',
        '渋谷駅',
      ])

      const routeOptimizeCall = mockFetch.mock.calls[1]
      const requestBody = JSON.parse(routeOptimizeCall[1].body)

      expect(requestBody.origin).toEqual({
        placeId: 'origin',
        name: '東京駅',
      })
      expect(requestBody.destination).toEqual({
        placeId: 'dest',
        name: '渋谷駅',
      })
      expect(requestBody.intermediates).toEqual([
        { placeId: 'mid1', name: '新宿駅' },
        { placeId: 'mid2', name: '池袋駅' },
      ])
    })

    it('デフォルトでDRIVEモードを使用する', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            places: [
              { placeId: 'p1', inputAddress: 'A' },
              { placeId: 'p2', inputAddress: 'B' },
            ],
          }),
      })

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      await client.optimizeRouteFromAddresses(['A', 'B'])

      const routeOptimizeCall = mockFetch.mock.calls[1]
      const requestBody = JSON.parse(routeOptimizeCall[1].body)

      expect(requestBody.travelMode).toBe('DRIVE')
    })

    it('カスタムtravelModeを受け入れる', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            success: true,
            places: [
              { placeId: 'p1', inputAddress: 'A' },
              { placeId: 'p2', inputAddress: 'B' },
            ],
          }),
      })

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      })

      await client.optimizeRouteFromAddresses(['A', 'B'], 'WALK')

      const routeOptimizeCall = mockFetch.mock.calls[1]
      const requestBody = JSON.parse(routeOptimizeCall[1].body)

      expect(requestBody.travelMode).toBe('WALK')
    })
  })

  describe('formatDistance', () => {
    it('1000m未満の場合はメートル単位で返す', () => {
      expect(client.formatDistance(500)).toBe('500 m')
      expect(client.formatDistance(999)).toBe('999 m')
      expect(client.formatDistance(0)).toBe('0 m')
    })

    it('1000m以上の場合はkm単位で小数点1桁で返す', () => {
      expect(client.formatDistance(1000)).toBe('1.0 km')
      expect(client.formatDistance(1500)).toBe('1.5 km')
      expect(client.formatDistance(10000)).toBe('10.0 km')
      expect(client.formatDistance(12345)).toBe('12.3 km')
    })
  })

  describe('formatDuration', () => {
    it('1時間未満の場合は分のみで返す', () => {
      expect(client.formatDuration(60)).toBe('1分')
      expect(client.formatDuration(300)).toBe('5分')
      expect(client.formatDuration(3599)).toBe('59分')
    })

    it('0秒の場合は0分を返す', () => {
      expect(client.formatDuration(0)).toBe('0分')
    })

    it('1時間以上の場合は時間と分で返す', () => {
      expect(client.formatDuration(3600)).toBe('1時間0分')
      expect(client.formatDuration(3660)).toBe('1時間1分')
      expect(client.formatDuration(7200)).toBe('2時間0分')
      expect(client.formatDuration(7380)).toBe('2時間3分')
    })

    it('大きな値を正しく処理する', () => {
      expect(client.formatDuration(86400)).toBe('24時間0分') // 1日
    })
  })
})
