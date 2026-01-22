import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { ScenarioGenerator } from './generator'
import { RouteInput, RouteSpot } from '../types/scenario'

// QwenClientとGeminiClientをモック
const mockQwenChat = vi.fn()
const mockGeminiChat = vi.fn()

vi.mock('../qwen-client', () => ({
  QwenClient: vi.fn().mockImplementation(() => ({
    chat: mockQwenChat
  }))
}))

vi.mock('../gemini-client', () => ({
  GeminiClient: vi.fn().mockImplementation(() => ({
    chat: mockGeminiChat
  }))
}))

describe('ScenarioGenerator', () => {
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
    it('APIキーなしでインスタンス化できる', () => {
      const generator = new ScenarioGenerator()
      expect(generator).toBeInstanceOf(ScenarioGenerator)
    })

    it('両方のAPIキーでインスタンス化できる', () => {
      const generator = new ScenarioGenerator('qwen-key', 'gemini-key')
      expect(generator).toBeInstanceOf(ScenarioGenerator)
    })
  })

  describe('parseLLMResponse（generateSpotを通じてテスト）', () => {
    let generator: ScenarioGenerator

    beforeEach(() => {
      generator = new ScenarioGenerator('qwen-key', 'gemini-key')
    })

    it('JSONコードブロックからシナリオとimagePromptを抽出する', async () => {
      mockQwenChat.mockResolvedValueOnce(`\`\`\`json
{
  "scenario": "これはシナリオです。",
  "imagePrompt": "A beautiful temple in Kyoto"
}
\`\`\``)

      const spot: RouteSpot = { name: 'テスト地点', type: 'waypoint' }
      const result = await generator.generateSpot('テストルート', spot, 'qwen', 'ja', true)

      expect(result.qwen).toBe('これはシナリオです。')
      expect(result.imagePrompt?.qwen).toBe('A beautiful temple in Kyoto')
    })

    it('直接JSONからシナリオを抽出する', async () => {
      mockQwenChat.mockResolvedValueOnce(`{"scenario": "直接JSONのシナリオ"}`)

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'qwen', 'ja')

      expect(result.qwen).toBe('直接JSONのシナリオ')
    })

    it('プレーンテキストはそのまま返す', async () => {
      mockQwenChat.mockResolvedValueOnce('これはプレーンテキストのシナリオです。')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'qwen', 'ja')

      expect(result.qwen).toBe('これはプレーンテキストのシナリオです。')
    })

    it('不正なJSONコードブロックはプレーンテキストとして扱う', async () => {
      mockQwenChat.mockResolvedValueOnce(`\`\`\`json
{ invalid json }
\`\`\``)

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'qwen', 'ja')

      expect(result.qwen).toContain('invalid json')
    })
  })

  describe('generateSpot', () => {
    let generator: ScenarioGenerator

    beforeEach(() => {
      generator = new ScenarioGenerator('qwen-key', 'gemini-key')
    })

    it('bothモードで両方のクライアントを呼び出す', async () => {
      mockQwenChat.mockResolvedValueOnce('Qwenシナリオ')
      mockGeminiChat.mockResolvedValueOnce('Geminiシナリオ')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'both', 'ja')

      expect(result.qwen).toBe('Qwenシナリオ')
      expect(result.gemini).toBe('Geminiシナリオ')
      expect(result.error).toBeUndefined()
    })

    it('qwenモードでQwenのみ呼び出す', async () => {
      mockQwenChat.mockResolvedValueOnce('Qwenシナリオ')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'qwen', 'ja')

      expect(result.qwen).toBe('Qwenシナリオ')
      expect(result.gemini).toBeUndefined()
      expect(mockGeminiChat).not.toHaveBeenCalled()
    })

    it('geminiモードでGeminiのみ呼び出す', async () => {
      mockGeminiChat.mockResolvedValueOnce('Geminiシナリオ')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'gemini', 'ja')

      expect(result.gemini).toBe('Geminiシナリオ')
      expect(result.qwen).toBeUndefined()
      expect(mockQwenChat).not.toHaveBeenCalled()
    })

    it('エラー時はerrorフィールドにエラーメッセージを設定する', async () => {
      mockQwenChat.mockRejectedValueOnce(new Error('Qwen API error'))
      mockGeminiChat.mockResolvedValueOnce('Geminiシナリオ')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'both', 'ja')

      expect(result.qwen).toBeUndefined()
      expect(result.gemini).toBe('Geminiシナリオ')
      expect(result.error?.qwen).toBe('Qwen API error')
      expect(result.error?.gemini).toBeUndefined()
    })

    it('includeImagePrompt=trueでimagePromptを含む', async () => {
      mockQwenChat.mockResolvedValueOnce(`\`\`\`json
{
  "scenario": "シナリオ",
  "imagePrompt": "Image prompt"
}
\`\`\``)
      mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "scenario": "シナリオ2",
  "imagePrompt": "Image prompt 2"
}
\`\`\``)

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'both', 'ja', true)

      expect(result.imagePrompt?.qwen).toBe('Image prompt')
      expect(result.imagePrompt?.gemini).toBe('Image prompt 2')
    })

    it('imagePromptが空の場合はフィールドを削除する', async () => {
      mockQwenChat.mockResolvedValueOnce('プレーンテキスト')
      mockGeminiChat.mockResolvedValueOnce('プレーンテキスト2')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'both', 'ja', true)

      expect(result.imagePrompt).toBeUndefined()
    })

    it('クライアントがない場合は結果に含まれない', async () => {
      const generator = new ScenarioGenerator('qwen-key') // Geminiなし
      mockQwenChat.mockResolvedValueOnce('Qwenシナリオ')

      const spot: RouteSpot = { name: 'テスト', type: 'waypoint' }
      const result = await generator.generateSpot('ルート', spot, 'both', 'ja')

      expect(result.qwen).toBe('Qwenシナリオ')
      expect(result.gemini).toBeUndefined()
    })
  })

  describe('generateRoute', () => {
    let generator: ScenarioGenerator

    beforeEach(() => {
      generator = new ScenarioGenerator('qwen-key', 'gemini-key')
    })

    it('waypointとdestinationのみ処理する', async () => {
      mockQwenChat.mockResolvedValue('シナリオ')
      mockGeminiChat.mockResolvedValue('シナリオ')

      const route: RouteInput = {
        routeName: 'テストルート',
        spots: [
          { name: '出発地', type: 'start' },
          { name: '経由地1', type: 'waypoint' },
          { name: '経由地2', type: 'waypoint' },
          { name: '目的地', type: 'destination' }
        ]
      }

      const result = await generator.generateRoute(route)

      // start以外の3つを処理
      expect(result.spots).toHaveLength(3)
      expect(result.spots[0].name).toBe('経由地1')
      expect(result.spots[1].name).toBe('経由地2')
      expect(result.spots[2].name).toBe('目的地')
    })

    it('統計情報を正しく計算する', async () => {
      mockQwenChat
        .mockResolvedValueOnce('シナリオ1')
        .mockRejectedValueOnce(new Error('error'))
      mockGeminiChat
        .mockResolvedValue('シナリオ')

      const route: RouteInput = {
        routeName: 'テストルート',
        spots: [
          { name: '経由地1', type: 'waypoint' },
          { name: '経由地2', type: 'waypoint' }
        ]
      }

      const result = await generator.generateRoute(route, 'both')

      expect(result.stats.totalSpots).toBe(2)
      expect(result.stats.successCount.qwen).toBe(1)
      expect(result.stats.successCount.gemini).toBe(2)
      expect(result.stats.processingTimeMs).toBeGreaterThanOrEqual(0)
    })

    it('generatedAtとrouteNameを含む', async () => {
      mockQwenChat.mockResolvedValue('シナリオ')
      mockGeminiChat.mockResolvedValue('シナリオ')

      const route: RouteInput = {
        routeName: 'テストルート',
        spots: [{ name: '経由地', type: 'waypoint' }]
      }

      const result = await generator.generateRoute(route)

      expect(result.routeName).toBe('テストルート')
      expect(result.generatedAt).toBeDefined()
    })
  })

  describe('generateSingleSpot', () => {
    let generator: ScenarioGenerator

    beforeEach(() => {
      generator = new ScenarioGenerator('qwen-key', 'gemini-key')
    })

    it('簡易形式でシナリオを生成する', async () => {
      mockQwenChat.mockResolvedValueOnce('Qwenシナリオ')
      mockGeminiChat.mockResolvedValueOnce('Geminiシナリオ')

      const result = await generator.generateSingleSpot(
        'テストルート',
        '清水寺',
        '有名な寺院',
        '見どころ',
        'both'
      )

      expect(result.qwen).toBe('Qwenシナリオ')
      expect(result.gemini).toBe('Geminiシナリオ')
    })

    it('スポットタイプはwaypointになる', async () => {
      mockQwenChat.mockResolvedValueOnce('シナリオ')

      // generateSpotが正しいspotオブジェクトで呼ばれることを確認
      const result = await generator.generateSingleSpot('ルート', 'スポット', undefined, undefined, 'qwen')

      expect(result.qwen).toBe('シナリオ')
    })
  })
})
