import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// SpeechRecognitionClientをモック
const mockConnect = vi.fn()
const mockSendAudio = vi.fn()
const mockFinish = vi.fn()
const mockSetCallbacks = vi.fn()

vi.mock('../../src/speech-recognition-client', () => ({
  SpeechRecognitionClient: vi.fn().mockImplementation(() => ({
    connect: mockConnect,
    sendAudio: mockSendAudio,
    finish: mockFinish,
    setCallbacks: mockSetCallbacks,
  })),
}))

// configをモック
const mockGetEnv = vi.fn()

vi.mock('../../src/config', () => ({
  getEnv: () => mockGetEnv(),
}))

// NextRequestとNextResponseをモック
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

import { POST } from '@/app/api/speech/recognize/route'

describe('POST /api/speech/recognize', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    mockGetEnv.mockReturnValue({
      qwenApiKey: 'test-qwen-key',
      qwenRegion: 'international',
    })

    mockConnect.mockResolvedValue(undefined)
    mockFinish.mockResolvedValue(undefined)
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  function createMockAudioFile(
    content = 'audio-data',
    name = 'test.wav',
    type = 'audio/wav'
  ) {
    return new File([content], name, { type })
  }

  function createFormDataRequest(audioFile?: File | null, config?: object) {
    const formData = new Map<string, File | string | null>()
    if (audioFile !== undefined) {
      formData.set('audio', audioFile)
    }
    if (config) {
      formData.set('config', JSON.stringify(config))
    }

    return {
      formData: vi.fn().mockResolvedValue({
        get: (key: string) => formData.get(key) ?? null,
      }),
    } as unknown as Request
  }

  describe('バリデーション', () => {
    it('音声ファイルがない場合は400エラー', async () => {
      const request = createFormDataRequest(null)

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('音声ファイルが必要です')
    })

    it('無効なconfig JSONで400エラー', async () => {
      const formData = new Map<string, File | string | null>()
      formData.set('audio', createMockAudioFile())
      formData.set('config', 'invalid-json')

      const request = {
        formData: vi.fn().mockResolvedValue({
          get: (key: string) => formData.get(key) ?? null,
        }),
      } as unknown as Request

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toBe('設定のJSONが無効です')
    })
  })

  describe('APIキーチェック', () => {
    it('QWEN_API_KEYがない場合は500エラー', async () => {
      mockGetEnv.mockReturnValue({ qwenApiKey: undefined })

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('QWEN_API_KEY が設定されていません')
    })
  })

  describe('成功ケース', () => {
    it('正常に音声認識結果を返す', async () => {
      // コールバックを通じてテキストを返す
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        // connectの後にコールバックが呼ばれるようにする
        mockConnect.mockImplementation(async () => {
          callbacks.onTranscriptionText('こんにちは', false)
          callbacks.onTranscriptionText('世界', false)
          callbacks.onTranscriptionCompleted('こんにちは世界')
        })
      })

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.text).toBe('こんにちは世界')
      expect((response as any)._data.transcriptions).toEqual(['こんにちは', '世界'])
    })

    it('部分的な結果は含めない', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onTranscriptionText('途中...', true) // isPartial = true
          callbacks.onTranscriptionText('完了', false) // isPartial = false
        })
      })

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect((response as any)._data.transcriptions).toEqual(['完了'])
    })

    it('SpeechRecognitionClientを正しく作成する', async () => {
      const { SpeechRecognitionClient } = await import(
        '../../src/speech-recognition-client'
      )

      const request = createFormDataRequest(createMockAudioFile(), {
        language: 'ja',
      })

      await POST(request as any)

      expect(SpeechRecognitionClient).toHaveBeenCalledWith(
        'test-qwen-key',
        'international',
        { language: 'ja' }
      )
    })

    it('音声データをチャンクで送信する', async () => {
      const audioData = new Array(10000).fill('x').join('')
      const audioFile = createMockAudioFile(audioData)

      const request = createFormDataRequest(audioFile)

      await POST(request as any)

      // sendAudioが複数回呼ばれることを確認
      expect(mockSendAudio).toHaveBeenCalled()
      expect(mockFinish).toHaveBeenCalled()
    })
  })

  describe('エラーケース', () => {
    it('接続エラー時は500エラー', async () => {
      // コールバックをリセットして、connectが純粋にrejectするようにする
      mockSetCallbacks.mockImplementation(() => {})
      mockConnect.mockRejectedValue(new Error('Connection failed'))

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Connection failed')
    })

    it('ASRエラー時は500エラー', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onError({ code: 'ASR_ERROR', message: 'Recognition failed' })
        })
      })

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toContain('ASR Error')
    })

    it('Error型でないエラーもハンドリング', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onError('String error')
        })
      })

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect(response.status).toBe(500)
    })

    it('finish時のエラーもハンドリング', async () => {
      // コールバックをリセットしてエラーがセットされないようにする
      mockSetCallbacks.mockImplementation(() => {})
      mockFinish.mockRejectedValue(new Error('Finish failed'))

      const request = createFormDataRequest(createMockAudioFile())

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Finish failed')
    })
  })
})
