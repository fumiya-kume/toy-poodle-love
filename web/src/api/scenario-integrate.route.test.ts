import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// ScenarioIntegratorをモック
const mockIntegrate = vi.fn()

vi.mock('../../src/scenario/integrator', () => ({
  ScenarioIntegrator: vi.fn().mockImplementation(() => ({
    integrate: mockIntegrate,
  })),
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

import { POST } from '@/app/api/scenario/integrate/route'

describe('POST /api/scenario/integrate', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>
  let originalEnv: NodeJS.ProcessEnv

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    originalEnv = { ...process.env }

    process.env.QWEN_API_KEY = 'test-qwen-key'
    process.env.GEMINI_API_KEY = 'test-gemini-key'
    process.env.QWEN_REGION = 'international'
  })

  afterEach(() => {
    consoleErrorSpy.mockRestore()
    process.env = originalEnv
  })

  function createRequest(body: Record<string, unknown>) {
    return {
      json: vi.fn().mockResolvedValue(body),
    } as unknown as Request
  }

  const validIntegration = {
    routeName: 'テストルート',
    spots: [
      { name: 'スポット1', qwen: 'Qwenシナリオ', gemini: 'Geminiシナリオ' },
    ],
    sourceModel: 'qwen',
  }

  describe('バリデーション', () => {
    it('integrationがない場合は400エラー', async () => {
      const request = createRequest({})

      const response = await POST(request as any)

      expect(response.status).toBe(400)
      expect((response as any)._data.error).toContain('統合情報が不正です')
    })

    it('routeNameがない場合は400エラー', async () => {
      const request = createRequest({
        integration: { spots: [], sourceModel: 'qwen' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })

    it('spotsがない場合は400エラー', async () => {
      const request = createRequest({
        integration: { routeName: 'ルート', sourceModel: 'qwen' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })

    it('sourceModelがない場合は400エラー', async () => {
      const request = createRequest({
        integration: { routeName: 'ルート', spots: [] },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(400)
    })
  })

  describe('APIキーチェック', () => {
    it('sourceがqwenでgeminiキーがない場合はエラー（geminiで統合）', async () => {
      delete process.env.GEMINI_API_KEY

      const request = createRequest({ integration: validIntegration })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('GEMINI_API_KEYが設定されていません')
    })

    it('sourceがgeminiでqwenキーがない場合はエラー（qwenで統合）', async () => {
      delete process.env.QWEN_API_KEY

      const request = createRequest({
        integration: { ...validIntegration, sourceModel: 'gemini' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('QWEN_API_KEYが設定されていません')
    })

    it('明示的にintegrationLLMを指定した場合はそのキーを確認', async () => {
      delete process.env.QWEN_API_KEY

      const request = createRequest({
        integration: { ...validIntegration, integrationLLM: 'qwen' },
      })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('QWEN_API_KEYが設定されていません')
    })
  })

  describe('成功ケース', () => {
    it('正常に統合結果を返す', async () => {
      const mockResult = {
        integratedAt: '2024-01-01T00:00:00.000Z',
        routeName: 'テストルート',
        sourceModel: 'qwen',
        integrationLLM: 'gemini',
        integratedScript: '統合されたスクリプト',
        processingTimeMs: 100,
      }
      mockIntegrate.mockResolvedValue(mockResult)

      const request = createRequest({ integration: validIntegration })

      const response = await POST(request as any)

      expect(response.status).toBe(200)
      expect((response as any)._data.success).toBe(true)
      expect((response as any)._data.data).toEqual(mockResult)
    })

    it('ScenarioIntegratorを正しく呼び出す', async () => {
      mockIntegrate.mockResolvedValue({})

      const request = createRequest({ integration: validIntegration })

      await POST(request as any)

      expect(mockIntegrate).toHaveBeenCalledWith(validIntegration)
    })
  })

  describe('エラーケース', () => {
    it('統合エラー時は500エラー', async () => {
      mockIntegrate.mockRejectedValue(new Error('Integration failed'))

      const request = createRequest({ integration: validIntegration })

      const response = await POST(request as any)

      expect(response.status).toBe(500)
      expect((response as any)._data.error).toBe('Integration failed')
    })

    it('エラーメッセージがない場合はデフォルトメッセージ', async () => {
      mockIntegrate.mockRejectedValue({})

      const request = createRequest({ integration: validIntegration })

      const response = await POST(request as any)

      expect((response as any)._data.error).toBe('シナリオ統合に失敗しました')
    })
  })
})
