import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { RouteGenerator } from './generator'
import { RouteGenerationInput } from '../types/route'

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

describe('RouteGenerator', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
  })

  describe('constructor', () => {
    it('APIキーなしでインスタンス化できる', () => {
      const generator = new RouteGenerator()
      expect(generator).toBeInstanceOf(RouteGenerator)
    })

    it('Qwen APIキーのみでインスタンス化できる', () => {
      const generator = new RouteGenerator('qwen-api-key')
      expect(generator).toBeInstanceOf(RouteGenerator)
    })

    it('両方のAPIキーでインスタンス化できる', () => {
      const generator = new RouteGenerator('qwen-api-key', 'gemini-api-key')
      expect(generator).toBeInstanceOf(RouteGenerator)
    })
  })

  describe('generate', () => {
    const baseInput: RouteGenerationInput = {
      startPoint: '東京駅',
      purpose: '観光',
      spotCount: 3,
      model: 'gemini'
    }

    it('Geminiモデルで正常にルートを生成する', async () => {
      const generator = new RouteGenerator(undefined, 'gemini-api-key')
      mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "東京観光コース",
  "spots": [
    { "name": "東京駅", "type": "start", "description": "出発地点" },
    { "name": "皇居", "type": "waypoint", "description": "経由地" },
    { "name": "浅草", "type": "destination", "description": "目的地" }
  ]
}
\`\`\``)

      const result = await generator.generate(baseInput)

      expect(result.routeName).toBe('東京観光コース')
      expect(result.spots).toHaveLength(3)
      expect(result.model).toBe('gemini')
      expect(result.processingTimeMs).toBeGreaterThanOrEqual(0)
      expect(result.generatedAt).toBeDefined()
    })

    it('Qwenモデルで正常にルートを生成する', async () => {
      const generator = new RouteGenerator('qwen-api-key')
      mockQwenChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "京都散策コース",
  "spots": [
    { "name": "京都駅", "type": "start" },
    { "name": "清水寺", "type": "destination" }
  ]
}
\`\`\``)

      const result = await generator.generate({ ...baseInput, model: 'qwen' })

      expect(result.routeName).toBe('京都散策コース')
      expect(result.model).toBe('qwen')
    })

    it('Qwen APIキーがない場合はエラーをスローする', async () => {
      const generator = new RouteGenerator(undefined, 'gemini-api-key')

      await expect(generator.generate({ ...baseInput, model: 'qwen' }))
        .rejects.toThrow('Qwen API key is not configured')
    })

    it('Gemini APIキーがない場合はエラーをスローする', async () => {
      const generator = new RouteGenerator('qwen-api-key')

      await expect(generator.generate(baseInput))
        .rejects.toThrow('Gemini API key is not configured')
    })
  })

  describe('parseResponse', () => {
    // parseResponseはprivateメソッドなので、generateを通じてテストする
    let generator: RouteGenerator

    beforeEach(() => {
      generator = new RouteGenerator(undefined, 'gemini-api-key')
    })

    describe('JSONの抽出', () => {
      it('JSONコードブロックからJSONを抽出する', async () => {
        mockGeminiChat.mockResolvedValueOnce(`以下がルートです：
\`\`\`json
{
  "routeName": "テストルート",
  "spots": [{ "name": "地点A" }, { "name": "地点B" }]
}
\`\`\`
以上です。`)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 2, model: 'gemini'
        })

        expect(result.routeName).toBe('テストルート')
        expect(result.spots).toHaveLength(2)
      })

      it('直接JSONを抽出する', async () => {
        mockGeminiChat.mockResolvedValueOnce(`{
  "routeName": "直接JSON",
  "spots": [{ "name": "地点1" }, { "name": "地点2" }]
}`)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 2, model: 'gemini'
        })

        expect(result.routeName).toBe('直接JSON')
      })

      it('JSONが見つからない場合はエラーをスローする', async () => {
        mockGeminiChat.mockResolvedValueOnce('ルートを作成できませんでした。')

        await expect(generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 2, model: 'gemini'
        })).rejects.toThrow('Failed to extract JSON from LLM response')
      })
    })

    describe('スポットタイプの正規化', () => {
      it('最初のスポットをstartに正規化する', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": [
    { "name": "地点A", "type": "waypoint" },
    { "name": "地点B", "type": "waypoint" },
    { "name": "地点C", "type": "waypoint" }
  ]
}
\`\`\``)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 3, model: 'gemini'
        })

        expect(result.spots[0].type).toBe('start')
      })

      it('最後のスポットをdestinationに正規化する', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": [
    { "name": "地点A", "type": "waypoint" },
    { "name": "地点B", "type": "waypoint" },
    { "name": "地点C", "type": "waypoint" }
  ]
}
\`\`\``)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 3, model: 'gemini'
        })

        expect(result.spots[2].type).toBe('destination')
      })

      it('中間スポットはwaypointを維持する', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": [
    { "name": "A" },
    { "name": "B" },
    { "name": "C" }
  ]
}
\`\`\``)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 3, model: 'gemini'
        })

        expect(result.spots[1].type).toBe('waypoint')
      })
    })

    describe('バリデーション', () => {
      it('routeNameがない場合はエラーをスローする', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "spots": [{ "name": "A" }]
}
\`\`\``)

        await expect(generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })).rejects.toThrow('Invalid JSON structure: missing routeName or spots')
      })

      it('spotsがない場合はエラーをスローする', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト"
}
\`\`\``)

        await expect(generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })).rejects.toThrow('Invalid JSON structure: missing routeName or spots')
      })

      it('spotsが配列でない場合はエラーをスローする', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": "not an array"
}
\`\`\``)

        await expect(generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })).rejects.toThrow('Invalid JSON structure: missing routeName or spots')
      })

      it('spotにnameがない場合はエラーをスローする', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": [{ "description": "名前なし" }]
}
\`\`\``)

        await expect(generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })).rejects.toThrow('Spot at index 0 is missing name')
      })

      it('不正なJSONの場合はパースエラーをスローする', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{ invalid json }
\`\`\``)

        await expect(generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })).rejects.toThrow('Failed to parse JSON')
      })
    })

    describe('オプションフィールドの処理', () => {
      it('description, point, generatedNoteを保持する', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": [{
    "name": "地点A",
    "description": "説明文",
    "point": "ポイント",
    "generatedNote": "メモ"
  }]
}
\`\`\``)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })

        expect(result.spots[0].description).toBe('説明文')
        expect(result.spots[0].point).toBe('ポイント')
        expect(result.spots[0].generatedNote).toBe('メモ')
      })

      it('オプションフィールドがない場合はundefinedになる', async () => {
        mockGeminiChat.mockResolvedValueOnce(`\`\`\`json
{
  "routeName": "テスト",
  "spots": [{ "name": "地点A" }]
}
\`\`\``)

        const result = await generator.generate({
          startPoint: 'A', purpose: 'test', spotCount: 1, model: 'gemini'
        })

        expect(result.spots[0].description).toBeUndefined()
        expect(result.spots[0].point).toBeUndefined()
      })
    })
  })
})
