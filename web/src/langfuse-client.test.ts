import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// configモジュールをモック
const mockGetEnv = vi.fn()
const mockIsLangfuseEnabled = vi.fn()

vi.mock('./config', () => ({
  getEnv: () => mockGetEnv(),
  isLangfuseEnabled: () => mockIsLangfuseEnabled(),
}))

// Langfuseをモック
const mockFlushAsync = vi.fn()
const mockShutdownAsync = vi.fn()
const mockTraceUpdate = vi.fn()
const mockGenerationEnd = vi.fn()
const mockSpanEnd = vi.fn()

const mockGeneration = vi.fn(() => ({
  id: 'test-generation-id',
  end: mockGenerationEnd,
}))

const mockSpan = vi.fn(() => ({
  end: mockSpanEnd,
}))

const mockTrace = vi.fn(() => ({
  id: 'test-trace-id',
  generation: mockGeneration,
  span: mockSpan,
  update: mockTraceUpdate,
}))

const mockLangfuseInstance = {
  trace: mockTrace,
  flushAsync: mockFlushAsync,
  shutdownAsync: mockShutdownAsync,
}

vi.mock('langfuse', () => ({
  Langfuse: vi.fn(() => mockLangfuseInstance),
}))

describe('langfuse-client', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})

    // デフォルトのモック設定
    mockGetEnv.mockReturnValue({
      langfuseSecretKey: 'test-secret',
      langfusePublicKey: 'test-public',
      langfuseBaseUrl: 'https://cloud.langfuse.com',
    })
    mockIsLangfuseEnabled.mockReturnValue(true)
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    // モジュールキャッシュをクリア
    vi.resetModules()
  })

  describe('getLangfuse', () => {
    it('Langfuse無効時はnullを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(false)
      const { getLangfuse } = await import('./langfuse-client')

      const result = getLangfuse()

      expect(result).toBeNull()
    })

    it('有効時はLangfuseインスタンスを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { getLangfuse } = await import('./langfuse-client')

      const result = getLangfuse()

      expect(result).not.toBeNull()
      expect(result).toBe(mockLangfuseInstance)
    })

    it('シングルトンパターンでインスタンスを再利用する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { getLangfuse } = await import('./langfuse-client')

      const result1 = getLangfuse()
      const result2 = getLangfuse()

      expect(result1).toBe(result2)
    })
  })

  describe('wrapOpenAIWithLangfuse', () => {
    it('元のクライアントをそのまま返す', async () => {
      const { wrapOpenAIWithLangfuse } = await import('./langfuse-client')
      const mockOpenAIClient = { chat: { completions: { create: vi.fn() } } }

      const result = wrapOpenAIWithLangfuse(mockOpenAIClient as unknown as import('openai').default)

      expect(result).toBe(mockOpenAIClient)
    })
  })

  describe('createQwenTrace', () => {
    it('Langfuse無効時はnullを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(false)
      const { createQwenTrace } = await import('./langfuse-client')

      const result = createQwenTrace('test', 'input')

      expect(result).toBeNull()
    })

    it('有効時はトレースオブジェクトを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createQwenTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse() // インスタンスを初期化

      const result = createQwenTrace('test-trace', 'test input')

      expect(result).not.toBeNull()
      expect(result?.traceId).toBe('test-trace-id')
      expect(result?.generationId).toBe('test-generation-id')
    })

    it('トレースIDとジェネレーションIDを含む', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createQwenTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const result = createQwenTrace('test', 'input')

      expect(result?.traceId).toBeDefined()
      expect(result?.generationId).toBeDefined()
    })

    it('end関数が正しく動作する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createQwenTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const trace = createQwenTrace('test', 'input')
      await trace?.end('output', { totalTokens: 100, promptTokens: 50, completionTokens: 50 })

      expect(mockGenerationEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          output: 'output',
          usage: { total: 100, input: 50, output: 50 },
          level: 'DEFAULT',
        })
      )
      expect(mockTraceUpdate).toHaveBeenCalledWith({ output: 'output' })
      expect(mockFlushAsync).toHaveBeenCalled()
    })

    it('エラー時にlevelをERRORに設定する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createQwenTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const trace = createQwenTrace('test', 'input')
      const error = new Error('test error')
      await trace?.end('output', undefined, error)

      expect(mockGenerationEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          level: 'ERROR',
          statusMessage: 'test error',
        })
      )
    })
  })

  describe('createGeminiTrace', () => {
    it('Langfuse無効時はnullを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(false)
      const { createGeminiTrace } = await import('./langfuse-client')

      const result = createGeminiTrace('test', 'input')

      expect(result).toBeNull()
    })

    it('有効時はトレースオブジェクトを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createGeminiTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const result = createGeminiTrace('test-trace', 'test input')

      expect(result).not.toBeNull()
      expect(result?.traceId).toBe('test-trace-id')
      expect(result?.generationId).toBe('test-generation-id')
    })

    it('end関数が正しく動作する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createGeminiTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const trace = createGeminiTrace('test', 'input')
      await trace?.end('output')

      expect(mockGenerationEnd).toHaveBeenCalledWith(
        expect.objectContaining({
          output: 'output',
          level: 'DEFAULT',
        })
      )
      expect(mockFlushAsync).toHaveBeenCalled()
    })
  })

  describe('createScenarioTrace', () => {
    it('Langfuse無効時はnullを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(false)
      const { createScenarioTrace } = await import('./langfuse-client')

      const result = createScenarioTrace('test')

      expect(result).toBeNull()
    })

    it('有効時はトレースオブジェクトを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createScenarioTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const result = createScenarioTrace('test-scenario', { routeName: 'test' })

      expect(result).not.toBeNull()
      expect(result?.trace).toBeDefined()
    })

    it('addSpanが正しく動作する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createScenarioTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const trace = createScenarioTrace('test')
      const span = trace?.addSpan('test-span', { input: 'data' })
      span?.end({ output: 'result' })

      expect(mockSpan).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'test-span',
          input: { input: 'data' },
        })
      )
      expect(mockSpanEnd).toHaveBeenCalledWith({ output: { output: 'result' } })
    })

    it('end関数が正しく動作する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createScenarioTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const trace = createScenarioTrace('test')
      await trace?.end({ result: 'success' })

      expect(mockTraceUpdate).toHaveBeenCalledWith({ output: { result: 'success' } })
      expect(mockFlushAsync).toHaveBeenCalled()
    })
  })

  describe('createPipelineTrace', () => {
    it('Langfuse無効時はnullを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(false)
      const { createPipelineTrace } = await import('./langfuse-client')

      const result = createPipelineTrace('test')

      expect(result).toBeNull()
    })

    it('有効時はトレースオブジェクトを返す', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createPipelineTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const result = createPipelineTrace('test-pipeline', { step: 1 })

      expect(result).not.toBeNull()
      expect(result?.trace).toBeDefined()
    })

    it('addSpanが正しく動作する', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { createPipelineTrace, getLangfuse } = await import('./langfuse-client')
      getLangfuse()

      const trace = createPipelineTrace('test')
      const span = trace?.addSpan('pipeline-step', { data: 'input' })
      span?.end({ result: 'output' })

      expect(mockSpan).toHaveBeenCalled()
      expect(mockSpanEnd).toHaveBeenCalled()
    })
  })

  describe('shutdownLangfuse', () => {
    it('インスタンスがある場合はシャットダウンする', async () => {
      mockIsLangfuseEnabled.mockReturnValue(true)
      const { getLangfuse, shutdownLangfuse } = await import('./langfuse-client')
      getLangfuse() // インスタンスを作成

      await shutdownLangfuse()

      expect(mockShutdownAsync).toHaveBeenCalled()
    })

    it('インスタンスがない場合は何もしない', async () => {
      mockIsLangfuseEnabled.mockReturnValue(false)
      const { shutdownLangfuse } = await import('./langfuse-client')

      await shutdownLangfuse()

      expect(mockShutdownAsync).not.toHaveBeenCalled()
    })
  })
})
