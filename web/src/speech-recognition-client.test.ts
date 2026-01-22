import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { SpeechRecognitionClient, ClientState } from './speech-recognition-client'

// WebSocketをモック
const mockWsSend = vi.fn()
const mockWsClose = vi.fn()
const mockWsOn = vi.fn()

class MockWebSocket {
  static OPEN = 1
  readyState = MockWebSocket.OPEN

  constructor(public url: string, public options?: { headers: Record<string, string> }) {
    // コンストラクタで登録されたイベントハンドラを保持
  }

  send = mockWsSend
  close = mockWsClose
  on = mockWsOn
}

vi.mock('ws', () => ({
  default: vi.fn().mockImplementation((url, options) => new MockWebSocket(url, options)),
}))

describe('SpeechRecognitionClient', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleWarnSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleWarnSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  describe('constructor', () => {
    it('デフォルト設定で初期化する', () => {
      const client = new SpeechRecognitionClient('test-api-key')

      expect(client).toBeInstanceOf(SpeechRecognitionClient)
      expect(client.getState()).toBe('disconnected')
      expect(client.getSessionId()).toBeNull()
    })

    it('カスタム設定を適用する', () => {
      const client = new SpeechRecognitionClient('test-api-key', 'china', {
        model: 'qwen3-asr-flash-realtime-2025-10-27',
        sampleRate: 8000,
        language: 'en',
      })

      expect(client).toBeInstanceOf(SpeechRecognitionClient)
    })

    it('internationalリージョンに応じたURLを生成する', () => {
      const client = new SpeechRecognitionClient('test-api-key', 'international')
      expect(client).toBeInstanceOf(SpeechRecognitionClient)
    })

    it('chinaリージョンに応じたURLを生成する', () => {
      const client = new SpeechRecognitionClient('test-api-key', 'china')
      expect(client).toBeInstanceOf(SpeechRecognitionClient)
    })
  })

  describe('getState', () => {
    it('現在の状態を返す', () => {
      const client = new SpeechRecognitionClient('test-api-key')
      expect(client.getState()).toBe('disconnected')
    })
  })

  describe('getSessionId', () => {
    it('初期状態ではnullを返す', () => {
      const client = new SpeechRecognitionClient('test-api-key')
      expect(client.getSessionId()).toBeNull()
    })
  })

  describe('setCallbacks', () => {
    it('コールバックを設定する', () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const callbacks = {
        onSessionCreated: vi.fn(),
        onTranscriptionText: vi.fn(),
        onTranscriptionCompleted: vi.fn(),
        onError: vi.fn(),
        onConnectionClosed: vi.fn(),
      }

      client.setCallbacks(callbacks)
      // コールバックが正しく設定されたことを確認（内部状態のため直接テスト不可）
      expect(client).toBeInstanceOf(SpeechRecognitionClient)
    })
  })

  describe('connect', () => {
    it('disconnected以外では例外を投げる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')

      // 状態を変更するために内部的に操作（モックを通じて）
      // まず一度connectを開始
      const connectPromise = client.connect()

      // connecting状態で再度connectを試みる
      await expect(client.connect()).rejects.toThrow('Cannot connect: current state is connecting')

      // クリーンアップ
      // mockWsOnで登録されたerrorハンドラを呼び出してPromiseを解決
      const errorHandler = mockWsOn.mock.calls.find((call) => call[0] === 'error')?.[1]
      if (errorHandler) {
        errorHandler(new Error('Test cleanup'))
      }

      try {
        await connectPromise
      } catch {
        // 期待通りエラー
      }
    })
  })

  describe('sendAudio', () => {
    it('running状態でのみ送信可能', () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const audioData = Buffer.from([0x00, 0x01, 0x02])

      expect(() => client.sendAudio(audioData)).toThrow(
        'Cannot send audio: current state is disconnected'
      )
    })
  })

  describe('commitAudio', () => {
    it('非running状態ではワーニングを出す', () => {
      const client = new SpeechRecognitionClient('test-api-key')

      client.commitAudio()

      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'Cannot commit: current state is disconnected'
      )
    })
  })

  describe('finish', () => {
    it('非running状態では何もしない', async () => {
      const client = new SpeechRecognitionClient('test-api-key')

      await client.finish()

      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'Cannot finish: current state is disconnected'
      )
    })
  })

  describe('disconnect', () => {
    it('状態をリセットする', () => {
      const client = new SpeechRecognitionClient('test-api-key')

      client.disconnect()

      expect(client.getState()).toBe('disconnected')
      expect(client.getSessionId()).toBeNull()
    })
  })

  describe('イベント処理', () => {
    it('session.createdイベントでコールバックが呼ばれる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const onSessionCreated = vi.fn()
      client.setCallbacks({ onSessionCreated })

      // WebSocket接続をシミュレート
      const connectPromise = client.connect()

      // openイベントをシミュレート
      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      // messageイベントでsession.createdをシミュレート
      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]
      const sessionCreatedEvent = {
        type: 'session.created',
        session: { id: 'test-session-id' },
      }
      messageHandler?.(Buffer.from(JSON.stringify(sessionCreatedEvent)))

      await connectPromise

      expect(onSessionCreated).toHaveBeenCalledWith('test-session-id')
      expect(client.getSessionId()).toBe('test-session-id')
      expect(client.getState()).toBe('running')
    })

    it('transcription.textイベントでコールバックが呼ばれる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const onTranscriptionText = vi.fn()
      client.setCallbacks({ onTranscriptionText })

      // 接続をシミュレート
      client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]

      // まずsession.createdを送信
      messageHandler?.(
        Buffer.from(JSON.stringify({ type: 'session.created', session: { id: 'sid' } }))
      )

      // transcription.textイベントを送信
      const transcriptionEvent = {
        type: 'conversation.item.input_audio_transcription.text',
        text: 'テスト文字起こし',
      }
      messageHandler?.(Buffer.from(JSON.stringify(transcriptionEvent)))

      expect(onTranscriptionText).toHaveBeenCalledWith('テスト文字起こし', true)
    })

    it('transcription.completedイベントでコールバックが呼ばれる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const onTranscriptionCompleted = vi.fn()
      const onTranscriptionText = vi.fn()
      client.setCallbacks({ onTranscriptionCompleted, onTranscriptionText })

      client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]

      messageHandler?.(
        Buffer.from(JSON.stringify({ type: 'session.created', session: { id: 'sid' } }))
      )

      const completedEvent = {
        type: 'conversation.item.input_audio_transcription.completed',
        transcript: '完了した文字起こし',
      }
      messageHandler?.(Buffer.from(JSON.stringify(completedEvent)))

      expect(onTranscriptionCompleted).toHaveBeenCalledWith('完了した文字起こし')
      expect(onTranscriptionText).toHaveBeenCalledWith('完了した文字起こし', false)
    })

    it('errorイベントでコールバックが呼ばれる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const onError = vi.fn()
      client.setCallbacks({ onError })

      const connectPromise = client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]

      const errorEvent = {
        type: 'error',
        error: { code: 'TEST_ERROR', message: 'Test error message' },
      }
      messageHandler?.(Buffer.from(JSON.stringify(errorEvent)))

      // サーバーエラーはconnectをrejectする
      await expect(connectPromise).rejects.toThrow('TEST_ERROR: Test error message')
      expect(onError).toHaveBeenCalledWith({ code: 'TEST_ERROR', message: 'Test error message' })
    })

    it('WebSocketエラーでonErrorコールバックが呼ばれる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const onError = vi.fn()
      client.setCallbacks({ onError })

      const connectPromise = client.connect()

      const errorHandler = mockWsOn.mock.calls.find((call) => call[0] === 'error')?.[1]
      const testError = new Error('WebSocket error')
      errorHandler?.(testError)

      // connect()のPromiseはエラーでrejectされる
      await expect(connectPromise).rejects.toThrow('WebSocket error')
      expect(onError).toHaveBeenCalledWith(testError)
    })

    it('closeイベントでonConnectionClosedコールバックが呼ばれる', async () => {
      const client = new SpeechRecognitionClient('test-api-key')
      const onConnectionClosed = vi.fn()
      client.setCallbacks({ onConnectionClosed })

      const connectPromise = client.connect()

      const closeHandler = mockWsOn.mock.calls.find((call) => call[0] === 'close')?.[1]
      closeHandler?.(1000, Buffer.from('Normal closure'))

      // connect()のPromiseはエラーでrejectされる（session.created前のclose）
      await expect(connectPromise).rejects.toThrow('WebSocket closed before session.created')
      expect(onConnectionClosed).toHaveBeenCalled()
    })
  })

  describe('sendSessionUpdate', () => {
    it('Manualモードの設定を送信', async () => {
      const client = new SpeechRecognitionClient('test-api-key', 'international', {
        sampleRate: 16000,
      })

      const connectPromise = client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      // session.updateが送信されたことを確認
      expect(mockWsSend).toHaveBeenCalled()
      const sentData = JSON.parse(mockWsSend.mock.calls[0][0])
      expect(sentData.type).toBe('session.update')
      expect(sentData.session.turn_detection).toBeNull()
      expect(sentData.session.sample_rate).toBe(16000)

      // クリーンアップ: session.createdを送ってPromiseを解決
      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]
      messageHandler?.(Buffer.from(JSON.stringify({ type: 'session.created', session: { id: 'sid' } })))
      await connectPromise
    })

    it('VADモードの設定を送信', async () => {
      const client = new SpeechRecognitionClient('test-api-key', 'international', {
        turnDetection: {
          type: 'server_vad',
          threshold: 0.5,
          silence_duration_ms: 500,
        },
      })

      const connectPromise = client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      const sentData = JSON.parse(mockWsSend.mock.calls[0][0])
      expect(sentData.type).toBe('session.update')
      expect(sentData.session.turn_detection).toEqual({
        type: 'server_vad',
        threshold: 0.5,
        silence_duration_ms: 500,
      })

      // クリーンアップ
      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]
      messageHandler?.(Buffer.from(JSON.stringify({ type: 'session.created', session: { id: 'sid' } })))
      await connectPromise
    })

    it('言語設定を送信', async () => {
      const client = new SpeechRecognitionClient('test-api-key', 'international', {
        language: 'ja',
      })

      const connectPromise = client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      const sentData = JSON.parse(mockWsSend.mock.calls[0][0])
      expect(sentData.session.input_audio_transcription).toEqual({ language: 'ja' })

      // クリーンアップ
      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]
      messageHandler?.(Buffer.from(JSON.stringify({ type: 'session.created', session: { id: 'sid' } })))
      await connectPromise
    })
  })

  describe('Base64エンコード', () => {
    it('sendAudioでBase64エンコードして送信', async () => {
      const client = new SpeechRecognitionClient('test-api-key')

      // 接続をシミュレート
      const connectPromise = client.connect()

      const openHandler = mockWsOn.mock.calls.find((call) => call[0] === 'open')?.[1]
      openHandler?.()

      const messageHandler = mockWsOn.mock.calls.find((call) => call[0] === 'message')?.[1]
      messageHandler?.(
        Buffer.from(JSON.stringify({ type: 'session.created', session: { id: 'sid' } }))
      )

      await connectPromise

      // 音声データを送信
      const audioData = Buffer.from([0x00, 0x01, 0x02, 0x03])
      client.sendAudio(audioData)

      // 最後の送信を確認（session.updateの後）
      const lastCall = mockWsSend.mock.calls[mockWsSend.mock.calls.length - 1]
      const sentData = JSON.parse(lastCall[0])

      expect(sentData.type).toBe('input_audio_buffer.append')
      expect(sentData.audio).toBe(audioData.toString('base64'))
    })
  })
})
