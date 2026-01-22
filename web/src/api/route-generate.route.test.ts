import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// RouteGeneratorをモック
const mockGenerate = vi.fn()

vi.mock('../../src/route/generator', () => ({
  RouteGenerator: vi.fn().mockImplementation(() => ({
    generate: mockGenerate,
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

import { POST } from '@/app/api/route/generate/route'

describe('POST /api/route/generate', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

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

  const validInput = {
    startPoint: '東京駅',
    purpose: '観光',
    spotCount: 5,
    model: 'qwen',
  }

  describe('バリデーション', () => {
    it('inputがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('入力情報が不正です')
    })

    it('startPointがない場合は400エラー', async () => {
      const request = createRequest({
        input: { purpose: '観光', spotCount: 5, model: 'qwen' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })

    it('purposeがない場合は400エラー', async () => {
      const request = createRequest({
        input: { startPoint: '東京駅', spotCount: 5, model: 'qwen' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })

    it('spotCountが2以下の場合は400エラー', async () => {
      const request = createRequest({
        input: { ...validInput, spotCount: 2 },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('地点数は3〜8の範囲')
    })

    it('spotCountが9以上の場合は400エラー', async () => {
      const request = createRequest({
        input: { ...validInput, spotCount: 9 },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('地点数は3〜8の範囲')
    })

    it('modelが無効な場合は400エラー', async () => {
      const request = createRequest({
        input: { ...validInput, model: 'invalid' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('qwenまたはgemini')
    })
  })

  describe('APIキーチェック', () => {
    it('qwenモデルでAPIキーがない場合はエラー', async () => {
      const mockErrorResponse = { _data: { error: 'No key' }, status: 500 }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'qwen') return mockErrorResponse
        return null
      })

      const request = createRequest({ input: validInput })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })

    it('geminiモデルでAPIキーがない場合はエラー', async () => {
      const mockErrorResponse = { _data: { error: 'No key' }, status: 500 }
      mockRequireApiKey.mockImplementation((keyType) => {
        if (keyType === 'gemini') return mockErrorResponse
        return null
      })

      const request = createRequest({
        input: { ...validInput, model: 'gemini' },
      })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('成功ケース', () => {
    it('正常にルート生成結果を返す', async () => {
      const mockResult = {
        routeName: '東京観光ルート',
        spots: [{ name: 'スポット1' }],
      }
      mockGenerate.mockResolvedValue(mockResult)

      const request = createRequest({ input: validInput })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.data).toEqual(mockResult)
    })

    it('RouteGeneratorを正しく呼び出す', async () => {
      mockGenerate.mockResolvedValue({})

      const request = createRequest({ input: validInput })

      await POST(request as any)

      expect(mockGenerate).toHaveBeenCalledWith(validInput)
    })
  })

  describe('エラーケース', () => {
    it('生成エラー時は500エラー', async () => {
      mockGenerate.mockRejectedValue(new Error('Generation failed'))

      const request = createRequest({ input: validInput })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Generation failed')
    })
  })
})
