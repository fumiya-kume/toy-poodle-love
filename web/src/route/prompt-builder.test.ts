import { describe, it, expect } from 'vitest'
import { detectLanguageFromInput, resolveLanguage, buildRouteGenerationPrompt } from './prompt-builder'
import { RouteGenerationInput } from '../types/route'

describe('detectLanguageFromInput', () => {
  it('スタート地点に日本語が含まれる場合は日本語を返す', () => {
    const input: RouteGenerationInput = {
      startPoint: '東京駅',
      purpose: 'sightseeing',
      spotCount: 5,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('ja')
  })

  it('目的に日本語が含まれる場合は日本語を返す', () => {
    const input: RouteGenerationInput = {
      startPoint: 'Tokyo Station',
      purpose: '観光',
      spotCount: 5,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('ja')
  })

  it('スタート地点と目的の両方に日本語が含まれる場合は日本語を返す', () => {
    const input: RouteGenerationInput = {
      startPoint: '東京駅',
      purpose: '観光ツアー',
      spotCount: 5,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('ja')
  })

  it('日本語が含まれない場合は英語を返す', () => {
    const input: RouteGenerationInput = {
      startPoint: 'Tokyo Station',
      purpose: 'sightseeing',
      spotCount: 5,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('en')
  })

  it('ひらがなを検出する', () => {
    const input: RouteGenerationInput = {
      startPoint: 'とうきょう',
      purpose: 'tour',
      spotCount: 3,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('ja')
  })

  it('カタカナを検出する', () => {
    const input: RouteGenerationInput = {
      startPoint: 'トーキョー',
      purpose: 'tour',
      spotCount: 3,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('ja')
  })

  it('漢字のみを検出する', () => {
    const input: RouteGenerationInput = {
      startPoint: '京都',
      purpose: 'tour',
      spotCount: 3,
      model: 'qwen'
    }
    expect(detectLanguageFromInput(input)).toBe('ja')
  })
})

describe('resolveLanguage', () => {
  const baseInput: RouteGenerationInput = {
    startPoint: 'Tokyo Station',
    purpose: 'sightseeing',
    spotCount: 5,
    model: 'qwen'
  }

  it('言語が明示的に"ja"の場合はそのまま返す', () => {
    expect(resolveLanguage('ja', baseInput)).toBe('ja')
  })

  it('言語が明示的に"en"の場合はそのまま返す', () => {
    expect(resolveLanguage('en', baseInput)).toBe('en')
  })

  it('言語が"auto"の場合は入力から検出する', () => {
    expect(resolveLanguage('auto', baseInput)).toBe('en')

    const jaInput: RouteGenerationInput = {
      startPoint: '東京駅',
      purpose: 'sightseeing',
      spotCount: 5,
      model: 'qwen'
    }
    expect(resolveLanguage('auto', jaInput)).toBe('ja')
  })

  it('言語がundefinedの場合は入力から検出する', () => {
    expect(resolveLanguage(undefined, baseInput)).toBe('en')
  })
})

describe('buildRouteGenerationPrompt', () => {
  const input: RouteGenerationInput = {
    startPoint: 'Tokyo Station',
    purpose: 'sightseeing tour',
    spotCount: 5,
    model: 'qwen'
  }

  describe('日本語プロンプト', () => {
    it('スタート地点、目的、地点数が含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'ja')
      expect(prompt).toContain('Tokyo Station')
      expect(prompt).toContain('sightseeing tour')
      expect(prompt).toContain('5')
    })

    it('JSON形式の指示が含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'ja')
      expect(prompt).toContain('JSON形式')
      expect(prompt).toContain('routeName')
      expect(prompt).toContain('spots')
    })

    it('スポットタイプの説明が含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'ja')
      expect(prompt).toContain('start')
      expect(prompt).toContain('waypoint')
      expect(prompt).toContain('destination')
    })

    it('タクシー観光プランナーのコンテキストが含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'ja')
      expect(prompt).toContain('タクシー観光ルートプランナー')
    })
  })

  describe('英語プロンプト', () => {
    it('スタート地点、目的、地点数が含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'en')
      expect(prompt).toContain('Tokyo Station')
      expect(prompt).toContain('sightseeing tour')
      expect(prompt).toContain('5')
    })

    it('JSON形式の指示が含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'en')
      expect(prompt).toContain('JSON format')
      expect(prompt).toContain('routeName')
      expect(prompt).toContain('spots')
    })

    it('スポットタイプの説明が含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'en')
      expect(prompt).toContain('"start"')
      expect(prompt).toContain('"waypoint"')
      expect(prompt).toContain('"destination"')
    })

    it('タクシーツアープランナーのコンテキストが含まれる', () => {
      const prompt = buildRouteGenerationPrompt(input, 'en')
      expect(prompt).toContain('taxi tour route planner')
    })
  })

  describe('地点数の反映', () => {
    it('異なる地点数がプロンプトに反映される', () => {
      const input3: RouteGenerationInput = { ...input, spotCount: 3 }
      const input8: RouteGenerationInput = { ...input, spotCount: 8 }

      const prompt3 = buildRouteGenerationPrompt(input3, 'ja')
      const prompt8 = buildRouteGenerationPrompt(input8, 'ja')

      expect(prompt3).toContain('3')
      expect(prompt8).toContain('8')
    })
  })
})
