import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// QwenClientをモック
const mockQwenChat = vi.fn()

vi.mock('../../src/qwen-client', () => ({
  QwenClient: vi.fn().mockImplementation(() => ({
    chat: mockQwenChat,
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

import { POST } from '@/app/api/qwen/route'

describe('POST /api/qwen', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // デフォルト設定
    mockGetEnv.mockReturnValue({
      qwenApiKey: 'test-qwen-key',
      qwenRegion: 'international',
    })
    mockRequireApiKey.mockReturnValue(null)
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  // リクエストを作成するヘルパー
  function createRequest(body: Record<string, unknown>) {
    return {
      json: vi.fn().mockResolvedValue(body),
    } as unknown as Request
  }

  describe('バリデーション', () => {
    it('messageがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('メッセージが必要です')
    })

    it('messageが空文字の場合は400エラー', async () => {
      const request = createRequest({ message: '' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })
  })

  describe('APIキーチェック', () => {
    it('APIキーがない場合はエラーレスポンスを返す', async () => {
      const mockErrorResponse = {
        _data: { error: 'QWEN_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockReturnValue(mockErrorResponse)

      const request = createRequest({ message: 'test' })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('成功ケース', () => {
    it('正常なレスポンスを返す', async () => {
      mockQwenChat.mockResolvedValue('Hello from Qwen!')

      const request = createRequest({ message: 'Hello' })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.response).toBe('Hello from Qwen!')
    })

    it('QwenClientを正しく呼び出す', async () => {
      mockQwenChat.mockResolvedValue('Response')

      const request = createRequest({ message: 'Test message' })

      await POST(request as any)

      expect(mockQwenChat).toHaveBeenCalledWith('Test message')
    })
  })

  describe('エラーケース', () => {
    it('APIエラー時は500エラー', async () => {
      mockQwenChat.mockRejectedValue(new Error('API connection failed'))

      const request = createRequest({ message: 'test' })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('API connection failed')
    })

    it('エラーメッセージがない場合はデフォルトメッセージを返す', async () => {
      mockQwenChat.mockRejectedValue({})

      const request = createRequest({ message: 'test' })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Qwen APIの呼び出しに失敗しました')
    })
  })
})
