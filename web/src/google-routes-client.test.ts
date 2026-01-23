import { describe, it, expect, vi, beforeEach } from 'vitest'
import { GoogleRoutesClient } from './google-routes-client'
import { RouteOptimizationRequest, RouteWaypoint } from './types/place-route'

// グローバルfetchをモック
const mockFetch = vi.fn()
vi.stubGlobal('fetch', mockFetch)

describe('GoogleRoutesClient', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('constructor', () => {
    it('APIキーが渡されるとクライアントが初期化される', () => {
      const client = new GoogleRoutesClient('test-api-key')
      expect(client).toBeInstanceOf(GoogleRoutesClient)
    })

    it('APIキーがない場合はエラーをスローする', () => {
      expect(() => new GoogleRoutesClient('')).toThrow('Google Maps API key is required')
    })
  })

  describe('optimizeRoute', () => {
    let client: GoogleRoutesClient

    const createMockRequest = (): RouteOptimizationRequest => ({
      origin: {
        placeId: 'origin-place-id',
        name: 'Origin'
      },
      destination: {
        placeId: 'dest-place-id',
        name: 'Destination'
      },
      intermediates: [
        { placeId: 'waypoint1-place-id', name: 'Waypoint 1' },
        { placeId: 'waypoint2-place-id', name: 'Waypoint 2' }
      ]
    })

    beforeEach(() => {
      client = new GoogleRoutesClient('test-api-key')
    })

    it('正常なレスポンスの場合は最適化されたルートを返す', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          routes: [{
            legs: [
              { distanceMeters: 1000, duration: '300s' },
              { distanceMeters: 2000, duration: '600s' },
              { distanceMeters: 1500, duration: '450s' }
            ],
            distanceMeters: 4500,
            duration: '1350s',
            optimizedIntermediateWaypointIndex: [1, 0] // 順序が逆転
          }]
        })
      })

      const result = await client.optimizeRoute(createMockRequest())

      expect(result.orderedWaypoints).toHaveLength(4) // origin + 2 intermediates + destination
      expect(result.orderedWaypoints[0].originalIndex).toBe(-1) // origin
      expect(result.orderedWaypoints[1].originalIndex).toBe(1) // 最適化後の最初
      expect(result.orderedWaypoints[2].originalIndex).toBe(0) // 最適化後の2番目
      expect(result.orderedWaypoints[3].originalIndex).toBe(-2) // destination
      expect(result.totalDistanceMeters).toBe(4500)
      expect(result.totalDurationSeconds).toBe(1350)
      expect(result.legs).toHaveLength(3)
    })

    it('正しいパラメータでfetchが呼ばれる', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          routes: [{
            legs: [{ distanceMeters: 1000, duration: '300s' }],
            distanceMeters: 1000,
            duration: '300s'
          }]
        })
      })

      const request = createMockRequest()
      await client.optimizeRoute(request)

      expect(mockFetch).toHaveBeenCalledWith(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': 'test-api-key'
          })
        })
      )

      const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
      expect(callBody.origin).toEqual({ placeId: 'origin-place-id' })
      expect(callBody.destination).toEqual({ placeId: 'dest-place-id' })
      expect(callBody.optimizeWaypointOrder).toBe(true)
      expect(callBody.travelMode).toBe('DRIVE')
    })

    it('APIエラーの場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        text: async () => 'Invalid request'
      })

      await expect(client.optimizeRoute(createMockRequest()))
        .rejects.toThrow('Routes API error: 400 - Invalid request')
    })

    it('ルートが見つからない場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          routes: []
        })
      })

      await expect(client.optimizeRoute(createMockRequest()))
        .rejects.toThrow('No routes found')
    })

    it('routesがundefinedの場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({})
      })

      await expect(client.optimizeRoute(createMockRequest()))
        .rejects.toThrow('No routes found')
    })

    it('最適化インデックスがない場合は元の順序を使用する', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          routes: [{
            legs: [
              { distanceMeters: 1000, duration: '300s' },
              { distanceMeters: 2000, duration: '600s' },
              { distanceMeters: 1500, duration: '450s' }
            ],
            distanceMeters: 4500,
            duration: '1350s'
            // optimizedIntermediateWaypointIndex is missing
          }]
        })
      })

      const result = await client.optimizeRoute(createMockRequest())

      // 元の順序を維持
      expect(result.orderedWaypoints[1].originalIndex).toBe(0)
      expect(result.orderedWaypoints[2].originalIndex).toBe(1)
    })

    describe('waypoint変換', () => {
      it('placeIdを持つwaypointを正しく変換する', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '300s' }],
              distanceMeters: 1000,
              duration: '300s'
            }]
          })
        })

        const request: RouteOptimizationRequest = {
          origin: { placeId: 'place-123', name: 'Origin' },
          destination: { placeId: 'place-456', name: 'Dest' },
          intermediates: []
        }

        await client.optimizeRoute(request)

        const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
        expect(callBody.origin).toEqual({ placeId: 'place-123' })
        expect(callBody.destination).toEqual({ placeId: 'place-456' })
      })

      it('locationを持つwaypointを正しく変換する', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '300s' }],
              distanceMeters: 1000,
              duration: '300s'
            }]
          })
        })

        const request: RouteOptimizationRequest = {
          origin: {
            location: { latitude: 35.6812, longitude: 139.7671 },
            name: 'Origin'
          },
          destination: {
            location: { latitude: 34.6937, longitude: 135.5023 },
            name: 'Dest'
          },
          intermediates: []
        }

        await client.optimizeRoute(request)

        const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
        expect(callBody.origin.location.latLng).toEqual({
          latitude: 35.6812,
          longitude: 139.7671
        })
      })

      it('addressを持つwaypointを正しく変換する', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '300s' }],
              distanceMeters: 1000,
              duration: '300s'
            }]
          })
        })

        const request: RouteOptimizationRequest = {
          origin: { address: '東京駅', name: 'Origin' },
          destination: { address: '大阪駅', name: 'Dest' },
          intermediates: []
        }

        await client.optimizeRoute(request)

        const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
        expect(callBody.origin).toEqual({ address: '東京駅' })
        expect(callBody.destination).toEqual({ address: '大阪駅' })
      })

      it('有効なフィールドがない場合はエラーをスローする', async () => {
        const request: RouteOptimizationRequest = {
          origin: { name: 'Origin' } as RouteWaypoint,
          destination: { placeId: 'dest', name: 'Dest' },
          intermediates: []
        }

        await expect(client.optimizeRoute(request))
          .rejects.toThrow('Waypoint must have placeId, location, or address')
      })
    })

    describe('duration解析', () => {
      it('"123s"形式を正しく解析する', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '123s' }],
              distanceMeters: 1000,
              duration: '456s'
            }]
          })
        })

        const result = await client.optimizeRoute(createMockRequest())

        expect(result.legs[0].durationSeconds).toBe(123)
        expect(result.totalDurationSeconds).toBe(456)
      })

      it('不正な形式の場合は0を返す', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: 'invalid' }],
              distanceMeters: 1000,
              duration: 'also-invalid'
            }]
          })
        })

        const result = await client.optimizeRoute(createMockRequest())

        expect(result.legs[0].durationSeconds).toBe(0)
        expect(result.totalDurationSeconds).toBe(0)
      })

      it('数値のみの場合は0を返す', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '123' }],
              distanceMeters: 1000,
              duration: '456'
            }]
          })
        })

        const result = await client.optimizeRoute(createMockRequest())

        expect(result.legs[0].durationSeconds).toBe(0)
      })
    })

    describe('カスタムオプション', () => {
      it('travelModeを指定できる', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '300s' }],
              distanceMeters: 1000,
              duration: '300s'
            }]
          })
        })

        const request = {
          ...createMockRequest(),
          travelMode: 'WALK' as const
        }
        await client.optimizeRoute(request)

        const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
        expect(callBody.travelMode).toBe('WALK')
      })

      it('optimizeWaypointOrderをfalseに設定できる', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            routes: [{
              legs: [{ distanceMeters: 1000, duration: '300s' }],
              distanceMeters: 1000,
              duration: '300s'
            }]
          })
        })

        const request = {
          ...createMockRequest(),
          optimizeWaypointOrder: false
        }
        await client.optimizeRoute(request)

        const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
        expect(callBody.optimizeWaypointOrder).toBe(false)
      })
    })
  })
})
