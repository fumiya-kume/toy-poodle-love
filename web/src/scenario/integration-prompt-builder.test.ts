import { describe, it, expect } from 'vitest'
import {
  detectLanguageFromScenarios,
  buildIntegrationPrompt,
  getIntegrationSystemPrompt,
  INTEGRATION_SYSTEM_PROMPT,
} from './integration-prompt-builder'
import { SpotScenario } from '../types/scenario'

describe('integration-prompt-builder', () => {
  const createTestSpots = (
    overrides?: Partial<SpotScenario>[]
  ): SpotScenario[] => {
    const defaults: SpotScenario[] = [
      {
        name: 'スポット1',
        type: 'waypoint',
        qwen: '東京タワーは日本を代表するランドマークです。',
        gemini: 'Tokyo Tower is a landmark of Japan.',
      },
      {
        name: 'スポット2',
        type: 'waypoint',
        qwen: '浅草寺は東京最古の寺院です。',
        gemini: 'Senso-ji is the oldest temple in Tokyo.',
      },
    ]

    if (overrides) {
      return defaults.map((spot, index) => ({
        ...spot,
        ...(overrides[index] || {}),
      }))
    }
    return defaults
  }

  describe('detectLanguageFromScenarios', () => {
    it('日本語シナリオでjaを返す（qwenモデル）', () => {
      const spots = createTestSpots()

      const result = detectLanguageFromScenarios(spots, 'qwen')

      expect(result).toBe('ja')
    })

    it('日本語シナリオでjaを返す（geminiモデル）', () => {
      const spots: SpotScenario[] = [
        {
          name: 'Spot1',
          type: 'waypoint',
          qwen: 'English text',
          gemini: '日本語のテキスト',
        },
      ]

      const result = detectLanguageFromScenarios(spots, 'gemini')

      expect(result).toBe('ja')
    })

    it('英語シナリオでenを返す（qwenモデル）', () => {
      const spots: SpotScenario[] = [
        {
          name: 'Spot1',
          type: 'waypoint',
          qwen: 'This is English text only.',
          gemini: 'Also English.',
        },
      ]

      const result = detectLanguageFromScenarios(spots, 'qwen')

      expect(result).toBe('en')
    })

    it('英語シナリオでenを返す（geminiモデル）', () => {
      const spots: SpotScenario[] = [
        {
          name: 'Spot1',
          type: 'waypoint',
          qwen: 'Japanese text: 日本語',
          gemini: 'Only English here.',
        },
      ]

      const result = detectLanguageFromScenarios(spots, 'gemini')

      expect(result).toBe('en')
    })

    it('空のシナリオではenを返す', () => {
      const spots: SpotScenario[] = [
        { name: 'Spot1', type: 'waypoint', qwen: undefined, gemini: undefined },
      ]

      expect(detectLanguageFromScenarios(spots, 'qwen')).toBe('en')
      expect(detectLanguageFromScenarios(spots, 'gemini')).toBe('en')
    })

    it('ひらがなを検出する', () => {
      const spots: SpotScenario[] = [
        { name: 'Spot', type: 'waypoint', qwen: 'これはひらがな', gemini: 'English' },
      ]

      expect(detectLanguageFromScenarios(spots, 'qwen')).toBe('ja')
    })

    it('カタカナを検出する', () => {
      const spots: SpotScenario[] = [
        { name: 'Spot', type: 'waypoint', qwen: 'コレハカタカナ', gemini: 'English' },
      ]

      expect(detectLanguageFromScenarios(spots, 'qwen')).toBe('ja')
    })

    it('漢字を検出する', () => {
      const spots: SpotScenario[] = [
        { name: 'Spot', type: 'waypoint', qwen: '東京', gemini: 'English' },
      ]

      expect(detectLanguageFromScenarios(spots, 'qwen')).toBe('ja')
    })
  })

  describe('buildIntegrationPrompt', () => {
    it('日本語プロンプトを生成する', () => {
      const spots = createTestSpots()

      const result = buildIntegrationPrompt('テストルート', spots, 'qwen', 'ja')

      expect(result).toContain('テストルート')
      expect(result).toContain('あなたは旅行ガイドのシナリオ編集者です')
      expect(result).toContain('東京タワーは日本を代表するランドマークです')
      expect(result).toContain('浅草寺は東京最古の寺院です')
    })

    it('英語プロンプトを生成する', () => {
      const spots = createTestSpots()

      const result = buildIntegrationPrompt('Test Route', spots, 'gemini', 'en')

      expect(result).toContain('Test Route')
      expect(result).toContain('You are a scenario editor for travel guides')
      expect(result).toContain('Tokyo Tower is a landmark of Japan')
      expect(result).toContain('Senso-ji is the oldest temple in Tokyo')
    })

    it('言語自動検出が動作する（日本語）', () => {
      const spots = createTestSpots()

      const result = buildIntegrationPrompt('ルート', spots, 'qwen')

      expect(result).toContain('あなたは旅行ガイドのシナリオ編集者です')
    })

    it('言語自動検出が動作する（英語）', () => {
      const spots: SpotScenario[] = [
        {
          name: 'Spot',
          type: 'waypoint',
          qwen: 'Only English content here.',
          gemini: 'Also English.',
        },
      ]

      const result = buildIntegrationPrompt('Route', spots, 'qwen')

      expect(result).toContain('You are a scenario editor for travel guides')
    })

    it('シナリオセクションを正しく結合する', () => {
      const spots: SpotScenario[] = [
        { name: 'A', type: 'waypoint', qwen: 'シナリオA', gemini: 'Scenario A' },
        { name: 'B', type: 'waypoint', qwen: 'シナリオB', gemini: 'Scenario B' },
        { name: 'C', type: 'waypoint', qwen: 'シナリオC', gemini: 'Scenario C' },
      ]

      const result = buildIntegrationPrompt('ルート', spots, 'qwen', 'ja')

      expect(result).toContain('シナリオA')
      expect(result).toContain('シナリオB')
      expect(result).toContain('シナリオC')
    })

    it('nullのシナリオはフィルタリングされる', () => {
      const spots: SpotScenario[] = [
        { name: 'A', type: 'waypoint', qwen: 'シナリオA', gemini: undefined },
        { name: 'B', type: 'waypoint', qwen: undefined, gemini: undefined },
        { name: 'C', type: 'waypoint', qwen: 'シナリオC', gemini: undefined },
      ]

      const result = buildIntegrationPrompt('ルート', spots, 'qwen', 'ja')

      expect(result).toContain('シナリオA')
      expect(result).toContain('シナリオC')
      expect(result).not.toContain('undefined')
    })

    it('sourceModelに応じたシナリオを使用する（qwen）', () => {
      const spots: SpotScenario[] = [
        { name: 'Spot', type: 'waypoint', qwen: 'Qwen版', gemini: 'Gemini版' },
      ]

      const result = buildIntegrationPrompt('ルート', spots, 'qwen', 'ja')

      expect(result).toContain('Qwen版')
      expect(result).not.toContain('Gemini版')
    })

    it('sourceModelに応じたシナリオを使用する（gemini）', () => {
      const spots: SpotScenario[] = [
        { name: 'Spot', type: 'waypoint', qwen: 'Qwen版', gemini: 'Gemini版' },
      ]

      const result = buildIntegrationPrompt('Route', spots, 'gemini', 'en')

      expect(result).toContain('Gemini版')
      expect(result).not.toContain('Qwen版')
    })
  })

  describe('getIntegrationSystemPrompt', () => {
    it('日本語システムプロンプトを返す', () => {
      const result = getIntegrationSystemPrompt('ja')

      expect(result).toContain('シナリオ編集者')
      expect(result).toContain('観光ガイドのシナリオ')
    })

    it('英語システムプロンプトを返す', () => {
      const result = getIntegrationSystemPrompt('en')

      expect(result).toContain('scenario editor')
      expect(result).toContain('tour guide scripts')
    })
  })

  describe('INTEGRATION_SYSTEM_PROMPT', () => {
    it('後方互換性のために英語プロンプトがエクスポートされている', () => {
      expect(INTEGRATION_SYSTEM_PROMPT).toBe(getIntegrationSystemPrompt('en'))
    })
  })
})
