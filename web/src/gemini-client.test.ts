import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { GeminiClient } from './gemini-client'

// モックの型定義
const mockGenerateContent = vi.fn()
const mockGetGenerativeModel = vi.fn(() => ({
  generateContent: mockGenerateContent
}))

// @google/generative-aiをモック
vi.mock('@google/generative-ai', () => ({
  GoogleGenerativeAI: vi.fn().mockImplementation(() => ({
    getGenerativeModel: mockGetGenerativeModel
  }))
}))

describe('GeminiClient', () => {
  let client: GeminiClient
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    // console出力を抑制
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    client = new GeminiClient('test-api-key')
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  describe('constructor', () => {
    it('APIキーが渡されるとクライアントが初期化される', () => {
      expect(client).toBeInstanceOf(GeminiClient)
    })
  })

  describe('chat', () => {
    describe('成功ケース', () => {
      it('正常なレスポンスの場合はテキストを返す', async () => {
        mockGenerateContent.mockResolvedValueOnce({
          response: {
            text: () => 'Hello, World!'
          }
        })

        const result = await client.chat('Say hello')
        expect(result).toBe('Hello, World!')
      })

      it('generateContentが正しいパラメータで呼ばれる', async () => {
        mockGenerateContent.mockResolvedValueOnce({
          response: {
            text: () => 'Response'
          }
        })

        await client.chat('Test message')
        expect(mockGenerateContent).toHaveBeenCalledWith(
          'Test message',
          expect.objectContaining({ timeout: 90000 })
        )
      })
    })

    describe('リトライロジック', () => {
      it('429エラーの場合はリトライする', async () => {
        const error429 = { status: 429, message: 'Rate limited' }
        mockGenerateContent
          .mockRejectedValueOnce(error429)
          .mockResolvedValueOnce({
            response: {
              text: () => 'Success after retry'
            }
          })

        const result = await client.chat('Test')
        expect(result).toBe('Success after retry')
        expect(mockGenerateContent).toHaveBeenCalledTimes(2)
      })

      it('503エラーの場合はリトライする', async () => {
        const error503 = { status: 503, message: 'Service unavailable' }
        mockGenerateContent
          .mockRejectedValueOnce(error503)
          .mockResolvedValueOnce({
            response: {
              text: () => 'Success'
            }
          })

        const result = await client.chat('Test')
        expect(result).toBe('Success')
        expect(mockGenerateContent).toHaveBeenCalledTimes(2)
      })

      it('ETIMEDOUTエラーの場合はリトライする', async () => {
        const timeoutError = { code: 'ETIMEDOUT', message: 'Timeout' }
        mockGenerateContent
          .mockRejectedValueOnce(timeoutError)
          .mockResolvedValueOnce({
            response: {
              text: () => 'Success'
            }
          })

        const result = await client.chat('Test')
        expect(result).toBe('Success')
      })

      it('タイムアウトメッセージを含むエラーの場合はリトライする', async () => {
        const timeoutError = { message: 'Request timeout exceeded' }
        mockGenerateContent
          .mockRejectedValueOnce(timeoutError)
          .mockResolvedValueOnce({
            response: {
              text: () => 'Success'
            }
          })

        const result = await client.chat('Test')
        expect(result).toBe('Success')
      })

      it('最大リトライ回数を超えるとエラーをスローする', async () => {
        const error429 = { status: 429, message: 'Rate limited' }
        mockGenerateContent
          .mockRejectedValueOnce(error429)
          .mockRejectedValueOnce(error429)
          .mockRejectedValueOnce(error429)

        await expect(client.chat('Test')).rejects.toThrow('レート制限に達しました')
        expect(mockGenerateContent).toHaveBeenCalledTimes(3)
      })

      it('400エラーの場合はリトライしない', async () => {
        const error400 = { status: 400, message: 'Bad request' }
        mockGenerateContent.mockRejectedValueOnce(error400)

        await expect(client.chat('Test')).rejects.toThrow('リクエストが無効です')
        expect(mockGenerateContent).toHaveBeenCalledTimes(1)
      })
    })

    describe('エラーフォーマット', () => {
      it('400エラーの場合は適切なメッセージを返す', async () => {
        mockGenerateContent.mockRejectedValueOnce({
          status: 400,
          message: 'Invalid input'
        })

        await expect(client.chat('Test')).rejects.toThrow('リクエストが無効です')
      })

      it('401エラーの場合はAPIキーエラーメッセージを返す', async () => {
        mockGenerateContent.mockRejectedValueOnce({ status: 401 })

        await expect(client.chat('Test')).rejects.toThrow('APIキーが無効です')
      })

      it('403エラーの場合はAPIキーエラーメッセージを返す', async () => {
        mockGenerateContent.mockRejectedValueOnce({ status: 403 })

        await expect(client.chat('Test')).rejects.toThrow('APIキーが無効です')
      })

      it('429エラーの場合はレート制限メッセージを返す', async () => {
        mockGenerateContent
          .mockRejectedValue({ status: 429 })

        await expect(client.chat('Test')).rejects.toThrow('レート制限に達しました')
      })

      it('500エラーの場合はサーバーエラーメッセージを返す', async () => {
        mockGenerateContent.mockRejectedValueOnce({ status: 500 })

        await expect(client.chat('Test')).rejects.toThrow('サーバーエラー')
      })

      it('503エラーの場合はサービス利用不可メッセージを返す', async () => {
        mockGenerateContent
          .mockRejectedValue({ status: 503 })

        await expect(client.chat('Test')).rejects.toThrow('サービスが一時的に利用できません')
      })

      it('ECONNREFUSEDエラーの場合は接続拒否メッセージを返す', async () => {
        // ECONNREFUSEDはリトライ可能なので、全リトライ後のエラーをテスト
        mockGenerateContent.mockRejectedValue({ code: 'ECONNREFUSED' })

        await expect(client.chat('Test')).rejects.toThrow('接続拒否エラー')
      })

      it('ENOTFOUNDエラーの場合はDNSエラーメッセージを返す', async () => {
        // ENOTFOUNDはリトライ可能なので、全リトライ後のエラーをテスト
        mockGenerateContent.mockRejectedValue({ code: 'ENOTFOUND' })

        await expect(client.chat('Test')).rejects.toThrow('DNSエラー')
      })

      it('ETIMEDOUTエラーの場合はタイムアウトメッセージを返す', async () => {
        mockGenerateContent
          .mockRejectedValue({ code: 'ETIMEDOUT' })

        await expect(client.chat('Test')).rejects.toThrow('接続タイムアウト')
      })

      it('タイムアウトメッセージを含むエラーの場合はAPIタイムアウトを返す', async () => {
        mockGenerateContent
          .mockRejectedValue({ message: 'timeout exceeded' })

        await expect(client.chat('Test')).rejects.toThrow('APIタイムアウト')
      })

      it('一般的なエラーメッセージの場合はそのまま返す', async () => {
        mockGenerateContent.mockRejectedValueOnce({
          message: 'Something went wrong'
        })

        await expect(client.chat('Test')).rejects.toThrow('Something went wrong')
      })

      it('未知のエラーの場合は予期しないエラーメッセージを返す', async () => {
        mockGenerateContent.mockRejectedValueOnce({})

        await expect(client.chat('Test')).rejects.toThrow('予期しないエラー')
      })
    })
  })
})
