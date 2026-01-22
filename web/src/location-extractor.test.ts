import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { LocationExtractor } from './location-extractor'

// configモジュールをモック
const mockGetEnv = vi.fn()

vi.mock('./config', () => ({
  getEnv: () => mockGetEnv(),
}))

// QwenClientをモック
const mockQwenChat = vi.fn()

vi.mock('./qwen-client', () => ({
  QwenClient: vi.fn().mockImplementation(() => ({
    chat: mockQwenChat,
  })),
}))

// GeminiClientをモック
const mockGeminiChat = vi.fn()

vi.mock('./gemini-client', () => ({
  GeminiClient: vi.fn().mockImplementation(() => ({
    chat: mockGeminiChat,
  })),
}))

describe('LocationExtractor', () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // デフォルト: 両方のAPIキーが存在
    mockGetEnv.mockReturnValue({
      qwenApiKey: 'test-qwen-key',
      geminiApiKey: 'test-gemini-key',
      qwenRegion: 'international',
    })
  })

  afterEach(() => {
    consoleLogSpy.mockRestore()
    consoleErrorSpy.mockRestore()
  })

  describe('constructor', () => {
    it('両方のAPIキーでインスタンス化できる', () => {
      mockGetEnv.mockReturnValue({
        qwenApiKey: 'qwen-key',
        geminiApiKey: 'gemini-key',
        qwenRegion: 'international',
      })

      const extractor = new LocationExtractor()

      expect(extractor).toBeInstanceOf(LocationExtractor)
    })

    it('qwenのみでインスタンス化できる', () => {
      mockGetEnv.mockReturnValue({
        qwenApiKey: 'qwen-key',
        geminiApiKey: undefined,
        qwenRegion: 'international',
      })

      const extractor = new LocationExtractor()

      expect(extractor).toBeInstanceOf(LocationExtractor)
    })

    it('geminiのみでインスタンス化できる', () => {
      mockGetEnv.mockReturnValue({
        qwenApiKey: undefined,
        geminiApiKey: 'gemini-key',
        qwenRegion: 'international',
      })

      const extractor = new LocationExtractor()

      expect(extractor).toBeInstanceOf(LocationExtractor)
    })
  })

  describe('extract', () => {
    describe('geminiモデル', () => {
      it('正常に地点を抽出する', async () => {
        mockGeminiChat.mockResolvedValue(`\`\`\`json
{
  "origin": "東京駅",
  "destination": "渋谷駅",
  "waypoints": ["新宿駅"],
  "confidence": 0.9,
  "interpretation": "東京駅から渋谷駅へ、新宿経由で移動"
}
\`\`\``)

        const extractor = new LocationExtractor()
        const result = await extractor.extract('東京駅から新宿経由で渋谷駅まで', 'gemini')

        expect(result.origin).toBe('東京駅')
        expect(result.destination).toBe('渋谷駅')
        expect(result.waypoints).toEqual(['新宿駅'])
        expect(result.confidence).toBe(0.9)
      })

      it('APIキーがない場合はエラー', async () => {
        mockGetEnv.mockReturnValue({
          qwenApiKey: undefined,
          geminiApiKey: undefined,
        })

        const extractor = new LocationExtractor()

        await expect(extractor.extract('test', 'gemini')).rejects.toThrow(
          'Gemini APIキーが設定されていません'
        )
      })

      it('LLMエラー時は例外を投げる', async () => {
        mockGeminiChat.mockRejectedValue(new Error('API Error'))

        const extractor = new LocationExtractor()

        await expect(extractor.extract('test', 'gemini')).rejects.toThrow('API Error')
      })
    })

    describe('qwenモデル', () => {
      it('正常に地点を抽出する', async () => {
        mockQwenChat.mockResolvedValue(`\`\`\`json
{
  "origin": "大阪駅",
  "destination": "京都駅",
  "waypoints": [],
  "confidence": 0.85,
  "interpretation": "大阪から京都への直行"
}
\`\`\``)

        const extractor = new LocationExtractor()
        const result = await extractor.extract('大阪駅から京都駅まで', 'qwen')

        expect(result.origin).toBe('大阪駅')
        expect(result.destination).toBe('京都駅')
        expect(result.waypoints).toEqual([])
        expect(result.confidence).toBe(0.85)
      })

      it('APIキーがない場合はエラー', async () => {
        mockGetEnv.mockReturnValue({
          qwenApiKey: undefined,
          geminiApiKey: 'gemini-key',
        })

        const extractor = new LocationExtractor()

        await expect(extractor.extract('test', 'qwen')).rejects.toThrow(
          'Qwen APIキーが設定されていません'
        )
      })

      it('LLMエラー時は例外を投げる', async () => {
        mockQwenChat.mockRejectedValue(new Error('Qwen API Error'))

        const extractor = new LocationExtractor()

        await expect(extractor.extract('test', 'qwen')).rejects.toThrow('Qwen API Error')
      })
    })

    describe('デフォルトモデル', () => {
      it('デフォルトはgeminiを使用する', async () => {
        mockGeminiChat.mockResolvedValue(`\`\`\`json
{
  "origin": "駅",
  "destination": "空港",
  "waypoints": [],
  "confidence": 0.8,
  "interpretation": "駅から空港へ"
}
\`\`\``)

        const extractor = new LocationExtractor()
        await extractor.extract('駅から空港まで')

        expect(mockGeminiChat).toHaveBeenCalled()
        expect(mockQwenChat).not.toHaveBeenCalled()
      })
    })
  })

  describe('parseExtractedLocation', () => {
    it('正しいJSONを解析する', async () => {
      mockGeminiChat.mockResolvedValue(`{
  "origin": "A地点",
  "destination": "B地点",
  "waypoints": ["C地点"],
  "confidence": 0.7,
  "interpretation": "AからBへ"
}`)

      const extractor = new LocationExtractor()
      const result = await extractor.extract('test', 'gemini')

      expect(result.origin).toBe('A地点')
      expect(result.destination).toBe('B地点')
    })

    it('```json```ブロックを抽出する', async () => {
      mockGeminiChat.mockResolvedValue(`以下の結果です：
\`\`\`json
{
  "origin": "出発地",
  "destination": "目的地",
  "waypoints": [],
  "confidence": 0.9,
  "interpretation": "解釈"
}
\`\`\`
以上です。`)

      const extractor = new LocationExtractor()
      const result = await extractor.extract('test', 'gemini')

      expect(result.origin).toBe('出発地')
      expect(result.destination).toBe('目的地')
    })

    it('waypointsが配列でない場合は空配列にする', async () => {
      mockGeminiChat.mockResolvedValue(`{
  "origin": "A",
  "destination": "B",
  "waypoints": "経由地",
  "confidence": 0.5,
  "interpretation": "テスト"
}`)

      const extractor = new LocationExtractor()
      const result = await extractor.extract('test', 'gemini')

      expect(result.waypoints).toEqual([])
    })

    it('confidenceがない場合はデフォルト0.5', async () => {
      mockGeminiChat.mockResolvedValue(`{
  "origin": "A",
  "destination": "B",
  "waypoints": [],
  "interpretation": "テスト"
}`)

      const extractor = new LocationExtractor()
      const result = await extractor.extract('test', 'gemini')

      expect(result.confidence).toBe(0.5)
    })

    it('originがnullの場合', async () => {
      mockGeminiChat.mockResolvedValue(`{
  "origin": null,
  "destination": "B",
  "waypoints": [],
  "confidence": 0.5,
  "interpretation": "出発地不明"
}`)

      const extractor = new LocationExtractor()
      const result = await extractor.extract('test', 'gemini')

      expect(result.origin).toBeNull()
    })

    it('無効なJSONでエラーを投げる', async () => {
      mockGeminiChat.mockResolvedValue('これはJSONではありません')

      const extractor = new LocationExtractor()

      await expect(extractor.extract('test', 'gemini')).rejects.toThrow(
        'LLMからの応答を解析できませんでした'
      )
    })
  })
})
