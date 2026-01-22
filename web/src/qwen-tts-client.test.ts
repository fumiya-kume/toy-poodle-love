import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { EventEmitter } from 'events'

// WebSocketのモッククラス（vi.mockより先に定義する必要がある）
const mockInstances: MockWebSocket[] = []

class MockWebSocket extends EventEmitter {
  url: string
  options: { headers?: Record<string, string> }
  sentMessages: string[] = []
  readyState: number = 1 // OPEN

  constructor(url: string, options?: { headers?: Record<string, string> }) {
    super()
    this.url = url
    this.options = options || {}
    mockInstances.push(this)
  }

  send(data: string) {
    this.sentMessages.push(data)
  }

  close() {
    this.readyState = 3 // CLOSED
  }

  // テストヘルパー: イベントをシミュレート
  simulateOpen() {
    this.emit('open')
  }

  simulateMessage(data: object) {
    this.emit('message', Buffer.from(JSON.stringify(data)))
  }

  simulateError(error: Error) {
    this.emit('error', error)
  }

  simulateClose(code: number, reason: string) {
    this.emit('close', code, Buffer.from(reason))
  }
}

// wsモジュールをモック
vi.mock('ws', () => ({
  default: class extends EventEmitter {
    url: string
    options: { headers?: Record<string, string> }
    sentMessages: string[] = []
    readyState: number = 1

    constructor(url: string, options?: { headers?: Record<string, string> }) {
      super()
      this.url = url
      this.options = options || {}
      mockInstances.push(this as unknown as MockWebSocket)
    }

    send(data: string) {
      this.sentMessages.push(data)
    }

    close() {
      this.readyState = 3
    }
  },
}))

// モック後にインポート
import { QwenTTSClient, QwenTTSOptions } from './qwen-tts-client'

// インスタンスを取得するヘルパー
function getLastInstance(): MockWebSocket {
  return mockInstances[mockInstances.length - 1]
}

// イベントをシミュレートするヘルパー
function simulateOpen(ws: MockWebSocket) {
  ws.emit('open')
}

function simulateMessage(ws: MockWebSocket, data: object) {
  ws.emit('message', Buffer.from(JSON.stringify(data)))
}

function simulateError(ws: MockWebSocket, error: Error) {
  ws.emit('error', error)
}

function simulateClose(ws: MockWebSocket, code: number, reason: string) {
  ws.emit('close', code, Buffer.from(reason))
}

describe('QwenTTSClient', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    mockInstances.length = 0
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  describe('constructor', () => {
    it('internationalリージョンで正しいURLを設定する', () => {
      const client = new QwenTTSClient('test-api-key', 'international')
      expect(client).toBeInstanceOf(QwenTTSClient)
    })

    it('chinaリージョンで正しいURLを設定する', () => {
      const client = new QwenTTSClient('test-api-key', 'china')
      expect(client).toBeInstanceOf(QwenTTSClient)
    })

    it('デフォルトでinternationalリージョンを使用する', () => {
      const client = new QwenTTSClient('test-api-key')
      expect(client).toBeInstanceOf(QwenTTSClient)
    })
  })

  describe('synthesize', () => {
    let client: QwenTTSClient

    beforeEach(() => {
      client = new QwenTTSClient('test-api-key', 'international')
    })

    describe('接続ライフサイクル', () => {
      it('Authorizationヘッダー付きで接続する', async () => {
        const promise = client.synthesize('Hello')

        // WebSocketインスタンスが作成されるまで待つ
        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        expect(ws.options.headers?.Authorization).toBe('Bearer test-api-key')

        // セッションを完了させる
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('internationalリージョンで正しいURLに接続する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        expect(ws.url).toContain('dashscope-intl.aliyuncs.com')

        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('chinaリージョンで正しいURLに接続する', async () => {
        const chinaClient = new QwenTTSClient('test-api-key', 'china')
        const promise = chinaClient.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        expect(ws.url).toContain('dashscope.aliyuncs.com')
        expect(ws.url).not.toContain('dashscope-intl')

        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('WebSocketエラーでリジェクトする', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateError(ws, new Error('Connection failed'))

        await expect(promise).rejects.toThrow('QwenTTS WebSocket error: Connection failed')
      })

      it('セッション完了前に予期せず閉じられるとリジェクトする', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateClose(ws, 1006, 'Connection lost')

        await expect(promise).rejects.toThrow('QwenTTS WebSocket closed unexpectedly')
      })
    })

    describe('セッション状態機械', () => {
      it('session.createdでsession.updateを送信する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })

        expect(ws.sentMessages.length).toBeGreaterThan(0)
        const updateMessage = JSON.parse(ws.sentMessages[0])
        expect(updateMessage.type).toBe('session.update')
        expect(updateMessage.session.voice).toBe('Cherry') // デフォルト

        // セッションを完了させる
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('session.updatedでテキストを送信する', async () => {
        const promise = client.synthesize('こんにちは')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })

        // session.update + text append + text commit
        expect(ws.sentMessages.length).toBe(3)

        const appendMessage = JSON.parse(ws.sentMessages[1])
        expect(appendMessage.type).toBe('input_text_buffer.append')
        expect(appendMessage.text).toBe('こんにちは')

        const commitMessage = JSON.parse(ws.sentMessages[2])
        expect(commitMessage.type).toBe('input_text_buffer.commit')

        // セッションを完了させる
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('response.doneでsession.finishを送信する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })

        const finishMessage = JSON.parse(ws.sentMessages[ws.sentMessages.length - 1])
        expect(finishMessage.type).toBe('session.finish')

        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('session.finishedで結合された音声バッファを返す', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })

        // 音声データを送信（base64エンコードされた "audio1" と "audio2"）
        simulateMessage(ws, {
          type: 'response.audio.delta',
          delta: Buffer.from('audio1').toString('base64'),
        })
        simulateMessage(ws, {
          type: 'response.audio.delta',
          delta: Buffer.from('audio2').toString('base64'),
        })

        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        const result = await promise
        expect(result.toString()).toBe('audio1audio2')
      })
    })

    describe('音声処理', () => {
      it('base64エンコードされた音声チャンクを正しくデコードする', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })

        const testData = 'test audio data'
        simulateMessage(ws, {
          type: 'response.audio.delta',
          delta: Buffer.from(testData).toString('base64'),
        })

        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        const result = await promise
        expect(result.toString()).toBe(testData)
      })

      it('複数の音声チャンクを結合する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })

        for (let i = 0; i < 5; i++) {
          simulateMessage(ws, {
            type: 'response.audio.delta',
            delta: Buffer.from(`chunk${i}`).toString('base64'),
          })
        }

        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        const result = await promise
        expect(result.toString()).toBe('chunk0chunk1chunk2chunk3chunk4')
      })

      it('deltaがない場合はスキップする', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })

        // deltaなしのイベント
        simulateMessage(ws, { type: 'response.audio.delta' })

        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        const result = await promise
        expect(result.length).toBe(0)
      })
    })

    describe('エラーハンドリング', () => {
      it('サーバーエラーイベントでリジェクトする', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, {
          type: 'error',
          error: { message: 'Invalid voice' },
        })

        await expect(promise).rejects.toThrow('QwenTTS error: Invalid voice')
      })

      it('error.messageがない場合はUnknown errorを使用する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'error' })

        await expect(promise).rejects.toThrow('QwenTTS error: Unknown error')
      })

      it('JSON解析エラーでもクラッシュしない', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)

        // 不正なJSONを送信
        ws.emit('message', Buffer.from('invalid json'))

        // セッションは続行可能
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
        expect(consoleErrorSpy).toHaveBeenCalled()
      })
    })

    describe('オプション', () => {
      it('デフォルトでqwen3-tts-flash-realtimeモデルを使用する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        expect(ws.url).toContain('model=qwen3-tts-flash-realtime')

        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('デフォルトでCherryボイスを使用する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })

        const updateMessage = JSON.parse(ws.sentMessages[0])
        expect(updateMessage.session.voice).toBe('Cherry')

        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('デフォルトでpcmフォーマットを使用する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })

        const updateMessage = JSON.parse(ws.sentMessages[0])
        expect(updateMessage.session.response_format).toBe('pcm')

        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('デフォルトで24000サンプルレートを使用する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })

        const updateMessage = JSON.parse(ws.sentMessages[0])
        expect(updateMessage.session.sample_rate).toBe(24000)

        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })

      it('カスタムオプションを受け入れる', async () => {
        const options: QwenTTSOptions = {
          model: 'qwen3-tts-vc-realtime',
          voice: 'Tom',
          format: 'mp3',
          sampleRate: 48000,
        }

        const promise = client.synthesize('Hello', options)

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        expect(ws.url).toContain('model=qwen3-tts-vc-realtime')

        simulateOpen(ws)
        simulateMessage(ws, { type: 'session.created' })

        const updateMessage = JSON.parse(ws.sentMessages[0])
        expect(updateMessage.session.voice).toBe('Tom')
        expect(updateMessage.session.response_format).toBe('mp3')
        expect(updateMessage.session.sample_rate).toBe(48000)

        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
      })
    })

    describe('未知のイベント', () => {
      it('未知のイベントタイプをログに記録する', async () => {
        const promise = client.synthesize('Hello')

        await vi.waitFor(() => {
          expect(mockInstances.length).toBe(1)
        })

        const ws = getLastInstance()
        simulateOpen(ws)
        simulateMessage(ws, { type: 'unknown.event' })
        simulateMessage(ws, { type: 'session.created' })
        simulateMessage(ws, { type: 'session.updated' })
        simulateMessage(ws, { type: 'response.done' })
        simulateMessage(ws, { type: 'session.finished' })

        await promise
        expect(consoleLogSpy).toHaveBeenCalledWith('QwenTTS unknown event:', 'unknown.event')
      })
    })
  })
})
