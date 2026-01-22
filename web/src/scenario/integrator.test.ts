import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// QwenClientをモック
const mockQwenChat = vi.fn()

vi.mock('../qwen-client', () => ({
  QwenClient: vi.fn().mockImplementation(() => ({
    chat: mockQwenChat,
  })),
}))

// GeminiClientをモック
const mockGeminiChat = vi.fn()

vi.mock('../gemini-client', () => ({
  GeminiClient: vi.fn().mockImplementation(() => ({
    chat: mockGeminiChat,
  })),
}))

// integration-prompt-builderをモック
vi.mock('./integration-prompt-builder', () => ({
  buildIntegrationPrompt: vi.fn().mockReturnValue('mocked prompt'),
}))

import { ScenarioIntegrator } from './integrator'
import { QwenClient } from '../qwen-client'
import { GeminiClient } from '../gemini-client'
import { buildIntegrationPrompt } from './integration-prompt-builder'
import { ScenarioIntegrationInput } from '../types/scenario'

const MockQwenClient = vi.mocked(QwenClient)
const MockGeminiClient = vi.mocked(GeminiClient)
const mockBuildPrompt = vi.mocked(buildIntegrationPrompt)

describe('ScenarioIntegrator', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockBuildPrompt.mockReturnValue('mocked integration prompt')
  })

  describe('constructor', () => {
    it('QwenApiKeyがある場合はQwenClientを初期化する', () => {
      new ScenarioIntegrator('qwen-key', undefined, 'international')

      expect(MockQwenClient).toHaveBeenCalledWith('qwen-key', 'international')
      expect(MockGeminiClient).not.toHaveBeenCalled()
    })

    it('GeminiApiKeyがある場合はGeminiClientを初期化する', () => {
      new ScenarioIntegrator(undefined, 'gemini-key')

      expect(MockGeminiClient).toHaveBeenCalledWith('gemini-key')
      expect(MockQwenClient).not.toHaveBeenCalled()
    })

    it('両方のキーがある場合は両方のクライアントを初期化する', () => {
      new ScenarioIntegrator('qwen-key', 'gemini-key', 'china')

      expect(MockQwenClient).toHaveBeenCalledWith('qwen-key', 'china')
      expect(MockGeminiClient).toHaveBeenCalledWith('gemini-key')
    })

    it('キーがない場合はクライアントを初期化しない', () => {
      new ScenarioIntegrator()

      expect(MockQwenClient).not.toHaveBeenCalled()
      expect(MockGeminiClient).not.toHaveBeenCalled()
    })
  })

  describe('integrate', () => {
    describe('LLM選択ロジック', () => {
      it('integrationLLMが指定されていない場合はsourceModelと異なる方を選択する（qwen -> gemini）', async () => {
        mockGeminiChat.mockResolvedValue('integrated script')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: 'テストルート',
          spots: [
            {
              spotName: 'スポット1',
              qwenScenario: 'qwenシナリオ',
              geminiScenario: null,
            },
          ],
          sourceModel: 'qwen',
        }

        const result = await integrator.integrate(input)

        expect(mockGeminiChat).toHaveBeenCalled()
        expect(mockQwenChat).not.toHaveBeenCalled()
        expect(result.integrationLLM).toBe('gemini')
      })

      it('integrationLLMが指定されていない場合はsourceModelと異なる方を選択する（gemini -> qwen）', async () => {
        mockQwenChat.mockResolvedValue('integrated script')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: 'テストルート',
          spots: [
            {
              spotName: 'スポット1',
              qwenScenario: null,
              geminiScenario: 'geminiシナリオ',
            },
          ],
          sourceModel: 'gemini',
        }

        const result = await integrator.integrate(input)

        expect(mockQwenChat).toHaveBeenCalled()
        expect(mockGeminiChat).not.toHaveBeenCalled()
        expect(result.integrationLLM).toBe('qwen')
      })

      it('integrationLLMが明示的に指定された場合はそれを使用する', async () => {
        mockQwenChat.mockResolvedValue('integrated script')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: 'テストルート',
          spots: [],
          sourceModel: 'qwen',
          integrationLLM: 'qwen', // 同じモデルを明示的に指定
        }

        const result = await integrator.integrate(input)

        expect(mockQwenChat).toHaveBeenCalled()
        expect(mockGeminiChat).not.toHaveBeenCalled()
        expect(result.integrationLLM).toBe('qwen')
      })
    })

    describe('エラーハンドリング', () => {
      it('Qwenが選択されたがクライアントがない場合はエラーをスローする', async () => {
        const integrator = new ScenarioIntegrator(undefined, 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: 'テストルート',
          spots: [],
          sourceModel: 'gemini', // これによりqwenが選択される
        }

        await expect(integrator.integrate(input)).rejects.toThrow(
          'Qwen APIキーが設定されていません'
        )
      })

      it('Geminiが選択されたがクライアントがない場合はエラーをスローする', async () => {
        const integrator = new ScenarioIntegrator('qwen-key', undefined)
        const input: ScenarioIntegrationInput = {
          routeName: 'テストルート',
          spots: [],
          sourceModel: 'qwen', // これによりgeminiが選択される
        }

        await expect(integrator.integrate(input)).rejects.toThrow(
          'Gemini APIキーが設定されていません'
        )
      })
    })

    describe('出力フォーマット', () => {
      it('正しいScenarioIntegrationOutputを返す', async () => {
        mockGeminiChat.mockResolvedValue('統合されたスクリプト')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: '東京観光ルート',
          spots: [
            {
              spotName: '東京タワー',
              qwenScenario: 'タワーのシナリオ',
              geminiScenario: null,
            },
          ],
          sourceModel: 'qwen',
        }

        const result = await integrator.integrate(input)

        expect(result.routeName).toBe('東京観光ルート')
        expect(result.sourceModel).toBe('qwen')
        expect(result.integrationLLM).toBe('gemini')
        expect(result.integratedScript).toBe('統合されたスクリプト')
        expect(result.integratedAt).toBeDefined()
        expect(result.processingTimeMs).toBeGreaterThanOrEqual(0)
      })

      it('integratedAtはISO文字列である', async () => {
        mockGeminiChat.mockResolvedValue('script')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: 'ルート',
          spots: [],
          sourceModel: 'qwen',
        }

        const result = await integrator.integrate(input)

        // ISO 8601形式の検証
        const date = new Date(result.integratedAt)
        expect(date.toISOString()).toBe(result.integratedAt)
      })

      it('processingTimeMsは正の数である', async () => {
        mockGeminiChat.mockResolvedValue('script')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const input: ScenarioIntegrationInput = {
          routeName: 'ルート',
          spots: [],
          sourceModel: 'qwen',
        }

        const result = await integrator.integrate(input)

        expect(result.processingTimeMs).toBeTypeOf('number')
        expect(result.processingTimeMs).toBeGreaterThanOrEqual(0)
      })
    })

    describe('プロンプト構築', () => {
      it('buildIntegrationPromptを正しい引数で呼び出す', async () => {
        mockGeminiChat.mockResolvedValue('script')

        const integrator = new ScenarioIntegrator('qwen-key', 'gemini-key')
        const spots = [
          { spotName: 'スポット1', qwenScenario: 'シナリオ1', geminiScenario: null },
          { spotName: 'スポット2', qwenScenario: 'シナリオ2', geminiScenario: null },
        ]
        const input: ScenarioIntegrationInput = {
          routeName: 'マイルート',
          spots,
          sourceModel: 'qwen',
        }

        await integrator.integrate(input)

        expect(mockBuildPrompt).toHaveBeenCalledWith('マイルート', spots, 'qwen')
      })
    })
  })
})
