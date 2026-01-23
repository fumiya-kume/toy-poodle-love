import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// QwenTTSClientをモック
const mockSynthesize = vi.fn()

vi.mock('../../src/qwen-tts-client', () => ({
  QwenTTSClient: vi.fn().mockImplementation(() => ({
    synthesize: mockSynthesize,
  })),
}))

// configをモック
const mockGetEnv = vi.fn()
const mockRequireApiKey = vi.fn()

vi.mock('../../src/config/api-helpers', () => ({
  requireApiKey: (keyType: string) => mockRequireApiKey(keyType),
}))

vi.mock('../../src/config/env', () => ({
  getEnv: () => mockGetEnv(),
}))

// NextResponseをモック
vi.mock('next/server', () => ({
  NextRequest: vi.fn(),
  NextResponse: class MockNextResponse {
    static json(data: unknown, init?: { status?: number }) {
      return {
        _data: data,
        status: init?.status || 200,
        json: async () => data,
      }
    }

    constructor(
      public body: unknown,
      public init: { headers: Record<string, string> }
    ) {}
  },
}))

import { POST } from '@/app/api/tts/route'

describe('POST /api/tts', () => {
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

  function createRequest(body: Record<string, unknown>) {
    return {
      json: vi.fn().mockResolvedValue(body),
    } as unknown as Request
  }

  describe('APIキーチェック', () => {
    it('APIキーがない場合はエラーレスポンスを返す', async () => {
      const mockErrorResponse = {
        _data: { error: 'QWEN_API_KEY is not configured' },
        status: 500,
      }
      mockRequireApiKey.mockReturnValue(mockErrorResponse)

      const request = createRequest({ text: 'test' })

      const response = await POST(request as any)

      expect(response).toBe(mockErrorResponse)
    })
  })

  describe('バリデーション', () => {
    it('textがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('テキストが必要です')
    })

    it('textが空文字の場合は400エラー', async () => {
      const request = createRequest({ text: '   ' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('テキストが必要です')
    })

    it('無効なmodelで400エラー', async () => {
      const request = createRequest({ text: 'test', model: 'invalid-model' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('Invalid model')
    })

    it('無効なformatで400エラー', async () => {
      const request = createRequest({ text: 'test', format: 'invalid-format' })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('Invalid format')
    })

    it('無効なsampleRateで400エラー（小さすぎる）', async () => {
      const request = createRequest({ text: 'test', sampleRate: 100 })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('Sample rate must be between')
    })

    it('無効なsampleRateで400エラー（大きすぎる）', async () => {
      const request = createRequest({ text: 'test', sampleRate: 100000 })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('Sample rate must be between')
    })
  })

  describe('成功ケース', () => {
    it('PCM形式でWAVヘッダー付きレスポンスを返す', async () => {
      const mockAudioBuffer = Buffer.from([0x00, 0x01, 0x02, 0x03])
      mockSynthesize.mockResolvedValue(mockAudioBuffer)

      const request = createRequest({ text: 'テスト' })

      const response = await POST(request as any) as unknown as { init: { headers: Record<string, string> } }

      // WAVヘッダー（44バイト）+ データ（4バイト）= 48バイト
      expect(response.init.headers['Content-Type']).toBe('audio/wav')
    })

    it('WAV形式で正しいContent-Type', async () => {
      const mockAudioBuffer = Buffer.from([0x00, 0x01])
      mockSynthesize.mockResolvedValue(mockAudioBuffer)

      const request = createRequest({ text: 'テスト', format: 'wav' })

      const response = await POST(request as any) as unknown as { init: { headers: Record<string, string> } }

      expect(response.init.headers['Content-Type']).toBe('audio/wav')
    })

    it('MP3形式で正しいContent-Type', async () => {
      const mockAudioBuffer = Buffer.from([0x00, 0x01])
      mockSynthesize.mockResolvedValue(mockAudioBuffer)

      const request = createRequest({ text: 'テスト', format: 'mp3' })

      const response = await POST(request as any) as unknown as { init: { headers: Record<string, string> } }

      expect(response.init.headers['Content-Type']).toBe('audio/mpeg')
    })

    it('Opus形式で正しいContent-Type', async () => {
      const mockAudioBuffer = Buffer.from([0x00, 0x01])
      mockSynthesize.mockResolvedValue(mockAudioBuffer)

      const request = createRequest({ text: 'テスト', format: 'opus' })

      const response = await POST(request as any) as unknown as { init: { headers: Record<string, string> } }

      expect(response.init.headers['Content-Type']).toBe('audio/opus')
    })

    it('QwenTTSClientを正しく呼び出す', async () => {
      mockSynthesize.mockResolvedValue(Buffer.from([]))

      const request = createRequest({
        text: 'テストメッセージ',
        model: 'qwen3-tts-flash-realtime',
        voice: 'Maple',
        format: 'wav',
        sampleRate: 16000,
      })

      await POST(request as any)

      expect(mockSynthesize).toHaveBeenCalledWith('テストメッセージ', {
        model: 'qwen3-tts-flash-realtime',
        voice: 'Maple',
        format: 'wav',
        sampleRate: 16000,
      })
    })
  })

  describe('エラーケース', () => {
    it('APIエラー時は500エラー', async () => {
      mockSynthesize.mockRejectedValue(new Error('TTS synthesis failed'))

      const request = createRequest({ text: 'test' })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('TTS synthesis failed')
    })

    it('エラーメッセージがない場合はデフォルトメッセージを返す', async () => {
      mockSynthesize.mockRejectedValue({})

      const request = createRequest({ text: 'test' })

      const response = await POST(request as any)

      expect((response as any)._data.error).toBe('TTS APIの呼び出しに失敗しました')
    })
  })
})
