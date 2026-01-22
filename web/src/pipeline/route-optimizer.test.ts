import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { RouteOptimizerPipeline } from './route-optimizer'
import { PipelineRequest } from '../types/pipeline'

// 各クライアントをモック
const mockRouteGenerate = vi.fn()
const mockGeocodeBatch = vi.fn()
const mockOptimizeRoute = vi.fn()

vi.mock('../route/generator', () => ({
  RouteGenerator: vi.fn().mockImplementation(() => ({
    generate: mockRouteGenerate
  }))
}))

vi.mock('../google-places-client', () => ({
  GooglePlacesClient: vi.fn().mockImplementation(() => ({
    geocodeBatch: mockGeocodeBatch
  }))
}))

vi.mock('../google-routes-client', () => ({
  GoogleRoutesClient: vi.fn().mockImplementation(() => ({
    optimizeRoute: mockOptimizeRoute
  }))
}))

describe('RouteOptimizerPipeline', () => {
  let pipeline: RouteOptimizerPipeline
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  const baseRequest: PipelineRequest = {
    startPoint: '東京駅',
    purpose: '観光',
    spotCount: 3,
    model: 'gemini'
  }

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    pipeline = new RouteOptimizerPipeline({
      qwenApiKey: 'qwen-key',
      geminiApiKey: 'gemini-key',
      googleMapsApiKey: 'google-key'
    })
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  describe('constructor', () => {
    it('設定でインスタンス化できる', () => {
      expect(pipeline).toBeInstanceOf(RouteOptimizerPipeline)
    })
  })

  describe('execute', () => {
    describe('成功ケース', () => {
      it('全ステップが成功した場合はsuccess=trueを返す', async () => {
        // Step 1: ルート生成
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'テストルート',
          spots: [
            { name: '東京駅', type: 'start' },
            { name: '皇居', type: 'waypoint' },
            { name: '浅草', type: 'destination' }
          ],
          model: 'gemini',
          processingTimeMs: 100
        })

        // Step 2: ジオコーディング
        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: '東京駅', placeId: 'place1', location: { latitude: 35.68, longitude: 139.76 }, formattedAddress: '東京都' },
          { inputAddress: '皇居', placeId: 'place2', location: { latitude: 35.68, longitude: 139.75 }, formattedAddress: '皇居' },
          { inputAddress: '浅草', placeId: 'place3', location: { latitude: 35.71, longitude: 139.79 }, formattedAddress: '浅草' }
        ])

        // Step 3: ルート最適化
        mockOptimizeRoute.mockResolvedValueOnce({
          orderedWaypoints: [],
          legs: [{ distanceMeters: 1000, durationSeconds: 300 }],
          totalDistanceMeters: 5000,
          totalDurationSeconds: 1500
        })

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(true)
        expect(result.routeGeneration.status).toBe('completed')
        expect(result.geocoding.status).toBe('completed')
        expect(result.routeOptimization.status).toBe('completed')
        expect(result.totalProcessingTimeMs).toBeGreaterThanOrEqual(0)
      })

      it('各ステップの結果が含まれる', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート名',
          spots: [{ name: 'A', type: 'start' }, { name: 'B', type: 'destination' }],
          model: 'gemini'
        })

        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: 'A', placeId: 'p1', location: { latitude: 1, longitude: 1 }, formattedAddress: 'A' },
          { inputAddress: 'B', placeId: 'p2', location: { latitude: 2, longitude: 2 }, formattedAddress: 'B' }
        ])

        mockOptimizeRoute.mockResolvedValueOnce({
          orderedWaypoints: [],
          legs: [],
          totalDistanceMeters: 1000,
          totalDurationSeconds: 600
        })

        const result = await pipeline.execute(baseRequest)

        expect(result.routeGeneration.routeName).toBe('ルート名')
        expect(result.routeGeneration.spots).toHaveLength(2)
        expect(result.geocoding.places).toHaveLength(2)
        expect(result.routeOptimization.totalDistanceMeters).toBe(1000)
      })
    })

    describe('Step 1 失敗', () => {
      it('ルート生成が失敗した場合は早期終了する', async () => {
        mockRouteGenerate.mockRejectedValueOnce(new Error('AI generation failed'))

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(false)
        expect(result.routeGeneration.status).toBe('failed')
        expect(result.routeGeneration.error).toContain('AI generation failed')
        expect(result.geocoding.status).toBe('pending')
        expect(result.routeOptimization.status).toBe('pending')
        expect(mockGeocodeBatch).not.toHaveBeenCalled()
      })
    })

    describe('Step 2 失敗', () => {
      it('ジオコーディングが失敗した場合は早期終了する', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート',
          spots: [{ name: 'A' }, { name: 'B' }]
        })

        mockGeocodeBatch.mockRejectedValueOnce(new Error('Geocoding error'))

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(false)
        expect(result.routeGeneration.status).toBe('completed')
        expect(result.geocoding.status).toBe('failed')
        expect(result.routeOptimization.status).toBe('pending')
        expect(mockOptimizeRoute).not.toHaveBeenCalled()
      })

      it('有効なplaceが2つ未満の場合は失敗する', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート',
          spots: [{ name: 'A' }, { name: 'B' }, { name: 'C' }]
        })

        // 1つしか成功しない
        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: 'A', placeId: 'p1', location: { latitude: 1, longitude: 1 }, formattedAddress: 'A' }
        ])

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(false)
        expect(result.geocoding.status).toBe('failed')
        expect(result.geocoding.error).toContain('less than 2')
      })

      it('部分的なジオコーディング失敗は記録される', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート',
          spots: [{ name: 'A' }, { name: 'B' }, { name: 'C' }]
        })

        // 2つ成功、1つ失敗
        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: 'A', placeId: 'p1', location: { latitude: 1, longitude: 1 }, formattedAddress: 'A' },
          { inputAddress: 'C', placeId: 'p3', location: { latitude: 3, longitude: 3 }, formattedAddress: 'C' }
        ])

        mockOptimizeRoute.mockResolvedValueOnce({
          orderedWaypoints: [],
          legs: [],
          totalDistanceMeters: 1000,
          totalDurationSeconds: 600
        })

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(true)
        expect(result.geocoding.failedSpots).toContain('B')
      })
    })

    describe('Step 3 失敗', () => {
      it('ルート最適化が失敗した場合はエラーを返す', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート',
          spots: [{ name: 'A' }, { name: 'B' }]
        })

        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: 'A', placeId: 'p1', location: { latitude: 1, longitude: 1 }, formattedAddress: 'A' },
          { inputAddress: 'B', placeId: 'p2', location: { latitude: 2, longitude: 2 }, formattedAddress: 'B' }
        ])

        mockOptimizeRoute.mockRejectedValueOnce(new Error('Route optimization error'))

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(false)
        expect(result.routeGeneration.status).toBe('completed')
        expect(result.geocoding.status).toBe('completed')
        expect(result.routeOptimization.status).toBe('failed')
        expect(result.routeOptimization.error).toContain('Route optimization error')
      })
    })

    describe('ジオコーディングのアドレス優先順位', () => {
      it('pointが存在する場合はpointを優先してジオコーディングする', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート',
          spots: [
            { name: '東京駅', point: '東京都千代田区丸の内1丁目' },
            { name: '皇居', point: undefined }
          ]
        })

        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: '東京都千代田区丸の内1丁目', placeId: 'p1', location: { latitude: 1, longitude: 1 }, formattedAddress: 'A' },
          { inputAddress: '皇居', placeId: 'p2', location: { latitude: 2, longitude: 2 }, formattedAddress: 'B' }
        ])

        mockOptimizeRoute.mockResolvedValueOnce({
          orderedWaypoints: [],
          legs: [],
          totalDistanceMeters: 1000,
          totalDurationSeconds: 600
        })

        await pipeline.execute(baseRequest)

        // geocodeBatchに渡されるアドレスを確認
        expect(mockGeocodeBatch).toHaveBeenCalledWith([
          '東京都千代田区丸の内1丁目', // pointを優先
          '皇居' // pointがないのでname
        ])
      })
    })

    describe('エラーハンドリング', () => {
      it('予期しないエラーも捕捉される', async () => {
        // モック内で直接例外をスローするケース
        mockRouteGenerate.mockImplementationOnce(() => {
          throw 'Unexpected string error'
        })

        const result = await pipeline.execute(baseRequest)

        expect(result.success).toBe(false)
        // ルート生成ステップで捕捉されるため、そのエラーメッセージが返る
        expect(result.routeGeneration.status).toBe('failed')
        expect(result.routeGeneration.error).toBeDefined()
      })
    })

    describe('処理時間の計測', () => {
      it('各ステップの処理時間が計測される', async () => {
        mockRouteGenerate.mockResolvedValueOnce({
          routeName: 'ルート',
          spots: [{ name: 'A' }, { name: 'B' }]
        })

        mockGeocodeBatch.mockResolvedValueOnce([
          { inputAddress: 'A', placeId: 'p1', location: { latitude: 1, longitude: 1 }, formattedAddress: 'A' },
          { inputAddress: 'B', placeId: 'p2', location: { latitude: 2, longitude: 2 }, formattedAddress: 'B' }
        ])

        mockOptimizeRoute.mockResolvedValueOnce({
          orderedWaypoints: [],
          legs: [],
          totalDistanceMeters: 1000,
          totalDurationSeconds: 600
        })

        const result = await pipeline.execute(baseRequest)

        expect(result.routeGeneration.processingTimeMs).toBeGreaterThanOrEqual(0)
        expect(result.geocoding.processingTimeMs).toBeGreaterThanOrEqual(0)
        expect(result.routeOptimization.processingTimeMs).toBeGreaterThanOrEqual(0)
        expect(result.totalProcessingTimeMs).toBeGreaterThanOrEqual(0)
      })
    })
  })
})
