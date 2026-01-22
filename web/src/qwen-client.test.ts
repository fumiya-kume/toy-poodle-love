import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { QwenClient } from './qwen-client'

// モックの設定
const mockCreate = vi.fn()

vi.mock('openai', () => ({
  default: vi.fn().mockImplementation((config: { baseURL: string }) => ({
    chat: {
      completions: {
        create: mockCreate
      }
    },
    _baseURL: config.baseURL
  }))
}))

describe('QwenClient', () => {
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

  describe('constructor', () => {
    it('デフォルトはinternationalリージョンを使用する', () => {
      const client = new QwenClient('test-api-key')
      expect(client).toBeInstanceOf(QwenClient)
      // ログからリージョンを確認
      expect(consoleLogSpy).toHaveBeenCalledWith(
        'Qwen Client initialized:',
        expect.objectContaining({ region: 'international' })
      )
    })

    it('chinaリージョンを指定できる', () => {
      const client = new QwenClient('test-api-key', 'china')
      expect(client).toBeInstanceOf(QwenClient)
      expect(consoleLogSpy).toHaveBeenCalledWith(
        'Qwen Client initialized:',
        expect.objectContaining({ region: 'china' })
      )
    })

    it('internationalリージョンの場合は正しいURLを使用する', () => {
      new QwenClient('test-api-key', 'international')
      expect(consoleLogSpy).toHaveBeenCalledWith(
        'Qwen Client initialized:',
        expect.objectContaining({
          baseURL: 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1'
        })
      )
    })

    it('chinaリージョンの場合は正しいURLを使用する', () => {
      new QwenClient('test-api-key', 'china')
      expect(consoleLogSpy).toHaveBeenCalledWith(
        'Qwen Client initialized:',
        expect.objectContaining({
          baseURL: 'https://dashscope.aliyuncs.com/compatible-mode/v1'
        })
      )
    })
  })

  describe('chat', () => {
    let client: QwenClient

    beforeEach(() => {
      client = new QwenClient('test-api-key')
    })

    describe('成功ケース', () => {
      it('正常なレスポンスの場合はメッセージ内容を返す', async () => {
        mockCreate.mockResolvedValueOnce({
          choices: [
            {
              message: {
                content: 'Hello from Qwen!'
              }
            }
          ],
          model: 'qwen-turbo'
        })

        const result = await client.chat('Say hello')
        expect(result).toBe('Hello from Qwen!')
      })

      it('正しいパラメータでAPIが呼ばれる', async () => {
        mockCreate.mockResolvedValueOnce({
          choices: [{ message: { content: 'Response' } }],
          model: 'qwen-turbo'
        })

        await client.chat('Test message')
        expect(mockCreate).toHaveBeenCalledWith({
          model: 'qwen-turbo',
          messages: [
            {
              role: 'user',
              content: 'Test message'
            }
          ],
          temperature: 0.7,
          max_tokens: 2000
        })
      })

      it('レスポンスにcontentがない場合は"No response"を返す', async () => {
        mockCreate.mockResolvedValueOnce({
          choices: [{ message: {} }],
          model: 'qwen-turbo'
        })

        const result = await client.chat('Test')
        expect(result).toBe('No response')
      })

      it('choicesが空の場合は"No response"を返す', async () => {
        mockCreate.mockResolvedValueOnce({
          choices: [],
          model: 'qwen-turbo'
        })

        const result = await client.chat('Test')
        expect(result).toBe('No response')
      })
    })

    describe('エラーケース', () => {
      it('401エラーの場合はAPIキーエラーメッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({ status: 401 })

        await expect(client.chat('Test')).rejects.toThrow('APIキーが無効です')
      })

      it('429エラーの場合はレート制限メッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({ status: 429 })

        await expect(client.chat('Test')).rejects.toThrow('レート制限に達しました')
      })

      it('400エラーの場合はリクエスト無効メッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({
          status: 400,
          message: 'Invalid parameters'
        })

        await expect(client.chat('Test')).rejects.toThrow('リクエストが無効です')
      })

      it('ECONNREFUSEDエラーの場合はリージョン情報を含むメッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({ code: 'ECONNREFUSED' })

        const error = await client.chat('Test').catch(e => e)
        expect(error.message).toContain('international')
        expect(error.message).toContain('接続拒否エラー')
      })

      it('ENOTFOUNDエラーの場合はリージョン情報を含むメッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({ code: 'ENOTFOUND' })

        const error = await client.chat('Test').catch(e => e)
        expect(error.message).toContain('international')
        expect(error.message).toContain('DNSエラー')
      })

      it('ETIMEDOUTエラーの場合はタイムアウトメッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({ code: 'ETIMEDOUT' })

        await expect(client.chat('Test')).rejects.toThrow('接続タイムアウト')
      })

      it('APIConnectionErrorの場合はリージョン情報を含むメッセージをスローする', async () => {
        const error = new Error('Connection failed')
        Object.defineProperty(error, 'constructor', {
          value: { name: 'APIConnectionError' }
        })
        mockCreate.mockRejectedValueOnce(error)

        await expect(client.chat('Test')).rejects.toThrow('API接続エラー')
      })

      it('APITimeoutErrorの場合はAPIタイムアウトメッセージをスローする', async () => {
        const error = new Error('Timeout')
        Object.defineProperty(error, 'constructor', {
          value: { name: 'APITimeoutError' }
        })
        mockCreate.mockRejectedValueOnce(error)

        await expect(client.chat('Test')).rejects.toThrow('APIタイムアウト')
      })

      it('接続エラーメッセージを含む場合は詳細情報を含むメッセージをスローする', async () => {
        mockCreate.mockRejectedValueOnce({
          message: 'Connection error occurred',
          code: 'NETWORK_ERROR'
        })

        const error = await client.chat('Test').catch(e => e)
        expect(error.message).toContain('接続エラー')
        expect(error.message).toContain('Region: international')
      })

      it('一般的なエラーメッセージの場合はそのまま返す', async () => {
        mockCreate.mockRejectedValueOnce({
          message: 'Something went wrong'
        })

        await expect(client.chat('Test')).rejects.toThrow('Something went wrong')
      })

      it('未知のエラーの場合は予期しないエラーメッセージを返す', async () => {
        mockCreate.mockRejectedValueOnce({})

        await expect(client.chat('Test')).rejects.toThrow('予期しないエラー')
      })
    })

    describe('chinaリージョンでのエラー', () => {
      it('接続エラーにchinaリージョン情報が含まれる', async () => {
        const chinaClient = new QwenClient('test-api-key', 'china')
        mockCreate.mockRejectedValueOnce({ code: 'ECONNREFUSED' })

        await expect(chinaClient.chat('Test')).rejects.toThrow('china')
      })
    })
  })
})
