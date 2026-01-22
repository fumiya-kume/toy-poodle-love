import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// GeminiClientをモック
const mockGeminiChat = vi.fn()

vi.mock('../../src/gemini-client', () => ({
  GeminiClient: vi.fn().mockImplementation(() => ({
    chat: mockGeminiChat,
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

import { POST } from '@/app/api/gemini/route'

describe('POST /api/gemini', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // デフォルト設定
    mockGetEnv.mockReturnValue({
      geminiApiKey: 'test-gemini-key',
    })
    mockRequireApiKey.mockReturnValue(null)
  })

  afterEach(() => {
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
        _data: { error: 'GEMINI_API_KEY is not configured' },
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
      mockGeminiChat.mockResolvedValue('Hello from Gemini!')

      const request = createRequest({ message: 'Hello' })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.response).toBe('Hello from Gemini!')
    })

    it('GeminiClientを正しく呼び出す', async () => {
      mockGeminiChat.mockResolvedValue('Response')

      const request = createRequest({ message: 'Test message' })

      await POST(request as any)

      expect(mockGeminiChat).toHaveBeenCalledWith('Test message')
    })
  })

  describe('エラーケース', () => {
    it('APIエラー時は500エラー', async () => {
      mockGeminiChat.mockRejectedValue(new Error('API connection failed'))

      const request = createRequest({ message: 'test' })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Gemini APIの呼び出しに失敗しました')
    })
  })
})
