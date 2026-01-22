import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// LocationExtractorをモック
const mockExtract = vi.fn()

vi.mock('../../src/location-extractor', () => ({
  LocationExtractor: vi.fn().mockImplementation(() => ({
    extract: mockExtract,
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

import { POST } from '@/app/api/voice-route/extract/route'

describe('POST /api/voice-route/extract', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
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

    it('textが文字列でない場合は400エラー', async () => {
      const request = createRequest({ text: 123 })

      const response = await POST(request)

      expect(response.status).toBe(400)
    })

    it('textが空文字の場合は400エラー', async () => {
      const request = createRequest({ text: '   ' })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('テキストが空です')
    })

    it('無効なmodelで400エラー', async () => {
      const request = createRequest({ text: 'test', model: 'invalid' })

      const response = await POST(request)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('qwen')
    })
  })

  describe('成功ケース', () => {
    it('正常に地点を抽出する', async () => {
      const mockLocation = {
        origin: '東京駅',
        destination: '渋谷駅',
        waypoints: [],
        confidence: 0.9,
        interpretation: '東京駅から渋谷駅へ',
      }
      mockExtract.mockResolvedValue(mockLocation)

      const request = createRequest({ text: '東京駅から渋谷駅まで' })

      const response = await POST(request)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.location).toEqual(mockLocation)
    })

    it('デフォルトでgeminiモデルを使用', async () => {
      mockExtract.mockResolvedValue({})

      const request = createRequest({ text: 'テスト' })

      await POST(request)

      expect(mockExtract).toHaveBeenCalledWith('テスト', 'gemini')
    })

    it('qwenモデルを指定できる', async () => {
      mockExtract.mockResolvedValue({})

      const request = createRequest({ text: 'テスト', model: 'qwen' })

      await POST(request)

      expect(mockExtract).toHaveBeenCalledWith('テスト', 'qwen')
    })
  })

  describe('エラーケース', () => {
    it('抽出エラー時は500エラー', async () => {
      mockExtract.mockRejectedValue(new Error('Extraction failed'))

      const request = createRequest({ text: 'テスト' })

      const response = await POST(request)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Extraction failed')
    })

    it('エラーメッセージがない場合はデフォルトメッセージ', async () => {
      mockExtract.mockRejectedValue({})

      const request = createRequest({ text: 'テスト' })

      const response = await POST(request)

      expect((response as any)._data.error).toBe('地点の抽出に失敗しました')
    })
  })
})
