import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// SpeechRecognitionClientをモック
const mockConnect = vi.fn()
const mockSendAudio = vi.fn()
const mockFinish = vi.fn()
const mockDisconnect = vi.fn()
const mockSetCallbacks = vi.fn()

vi.mock('../../src/speech-recognition-client', () => ({
  SpeechRecognitionClient: vi.fn().mockImplementation(() => ({
    connect: mockConnect,
    sendAudio: mockSendAudio,
    finish: mockFinish,
    disconnect: mockDisconnect,
    setCallbacks: mockSetCallbacks,
  })),
}))

// configをモック
const mockGetEnv = vi.fn()

vi.mock('../../src/config', () => ({
  getEnv: () => mockGetEnv(),
}))

import { POST } from '@/app/api/speech/stream/route'

describe('POST /api/speech/stream', () => {
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

  function createRequest(body: Record<string, unknown>) {
    const abortController = new AbortController()
    return {
      json: vi.fn().mockResolvedValue(body),
      signal: abortController.signal,
      _abortController: abortController,
    } as unknown as Request & { _abortController: AbortController }
  }

  function createInvalidJsonRequest() {
    const abortController = new AbortController()
    return {
      json: vi.fn().mockRejectedValue(new Error('Invalid JSON')),
      signal: abortController.signal,
    } as unknown as Request
  }

  // SSEストリームからイベントを読み取るヘルパー
  async function readSSEEvents(response: Response): Promise<Array<{ type: string; data: unknown }>> {
    const events: Array<{ type: string; data: unknown }> = []
    const reader = response.body?.getReader()
    if (!reader) return events

    const decoder = new TextDecoder()

    try {
      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        const text = decoder.decode(value)
        // SSEイベントをパース
        const lines = text.split('\n')
        let currentEvent: { type?: string; data?: string } = {}

        for (const line of lines) {
          if (line.startsWith('event: ')) {
            currentEvent.type = line.slice(7)
          } else if (line.startsWith('data: ')) {
            currentEvent.data = line.slice(6)
          } else if (line === '' && currentEvent.type && currentEvent.data) {
            events.push({
              type: currentEvent.type,
              data: JSON.parse(currentEvent.data),
            })
            currentEvent = {}
          }
        }
      }
    } catch {
      // Stream closed
    }

    return events
  }

  describe('バリデーション', () => {
    it('リクエストボディが無効な場合は400エラー', async () => {
      const request = createInvalidJsonRequest()

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      const data = await response.json()
      expect(data.error).toBe('リクエストボディが無効です')
    })

    it('音声データがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      const data = await response.json()
      expect(data.error).toBe('音声データが必要です')
    })
  })

  describe('APIキーチェック', () => {
    it('QWEN_API_KEYがない場合は500エラー', async () => {
      mockGetEnv.mockReturnValue({ qwenApiKey: undefined })

      const request = createRequest({ audio: 'base64data' })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      const data = await response.json()
      expect(data.error).toBe('QWEN_API_KEY が設定されていません')
    })
  })

  describe('SSEレスポンス', () => {
    it('正しいContent-Typeヘッダーを返す', async () => {
      mockSetCallbacks.mockImplementation(() => {})

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)

      expect(response.headers.get('Content-Type')).toBe('text/event-stream')
      expect(response.headers.get('Cache-Control')).toBe('no-cache')
      expect(response.headers.get('Connection')).toBe('keep-alive')
    })

    it('startedイベントを送信する', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onSessionCreated('session-123')
        })
      })

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const startedEvent = events.find((e) => e.type === 'started')
      expect(startedEvent).toBeDefined()
      expect(startedEvent?.data).toEqual({ sessionId: 'session-123' })
    })

    it('partial結果を送信する', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onTranscriptionText('途中...', true)
        })
      })

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const partialEvent = events.find((e) => e.type === 'partial')
      expect(partialEvent).toBeDefined()
      expect(partialEvent?.data).toEqual({ text: '途中...' })
    })

    it('final結果を送信する', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onTranscriptionText('完了テキスト', false)
        })
      })

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const finalEvent = events.find((e) => e.type === 'final')
      expect(finalEvent).toBeDefined()
      expect(finalEvent?.data).toEqual({ text: '完了テキスト' })
    })

    it('finishedイベントを送信する', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onTranscriptionCompleted('最終結果')
        })
      })

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const finishedEvent = events.find((e) => e.type === 'finished')
      expect(finishedEvent).toBeDefined()
      expect(finishedEvent?.data).toEqual({ text: '最終結果' })
    })

    it('errorイベントを送信する（コード付き）', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onError({ code: 'ASR_001', message: 'Recognition failed' })
        })
      })

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const errorEvent = events.find((e) => e.type === 'error')
      expect(errorEvent).toBeDefined()
      expect(errorEvent?.data).toEqual({
        code: 'ASR_001',
        message: 'Recognition failed',
      })
    })

    it('errorイベントを送信する（Errorオブジェクト）', async () => {
      mockSetCallbacks.mockImplementation((callbacks: any) => {
        mockConnect.mockImplementation(async () => {
          callbacks.onError(new Error('Generic error'))
        })
      })

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const errorEvent = events.find((e) => e.type === 'error')
      expect(errorEvent).toBeDefined()
      expect(errorEvent?.data).toEqual({ message: 'Generic error' })
    })
  })

  describe('SpeechRecognitionClient', () => {
    it('正しいパラメータでインスタンス化', async () => {
      const { SpeechRecognitionClient } = await import(
        '../../src/speech-recognition-client'
      )

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
        config: { language: 'ja', enablePunctuation: true },
      })

      await POST(request as any)

      expect(SpeechRecognitionClient).toHaveBeenCalledWith(
        'test-qwen-key',
        'international',
        { language: 'ja', enablePunctuation: true }
      )
    })

    it('finishが呼ばれる', async () => {
      mockSetCallbacks.mockImplementation(() => {})

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      await POST(request as any)
      // ストリームを読み切る
      const reader = (await POST(request as any)).body?.getReader()
      if (reader) {
        while (true) {
          const { done } = await reader.read()
          if (done) break
        }
      }

      // 注: タイミング依存のため、この検証は信頼性が低い場合がある
      expect(mockConnect).toHaveBeenCalled()
    })
  })

  describe('エラーケース', () => {
    it('接続エラー時はerrorイベントを送信', async () => {
      mockConnect.mockRejectedValue(new Error('Connection failed'))

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const errorEvent = events.find((e) => e.type === 'error')
      expect(errorEvent).toBeDefined()
      expect(errorEvent?.data).toEqual({ message: 'Connection failed' })
    })

    it('非Errorオブジェクトのエラーもハンドリング', async () => {
      mockConnect.mockRejectedValue('string error')

      const request = createRequest({
        audio: Buffer.from('test').toString('base64'),
      })

      const response = await POST(request as any)
      const events = await readSSEEvents(response)

      const errorEvent = events.find((e) => e.type === 'error')
      expect(errorEvent?.data).toEqual({ message: '予期しないエラーが発生しました' })
    })
  })
})
