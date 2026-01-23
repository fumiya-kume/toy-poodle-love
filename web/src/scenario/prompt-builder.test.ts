import { describe, it, expect } from 'vitest'
import { detectLanguage, resolveLanguage, buildPrompt, getSystemPrompt, SYSTEM_PROMPT } from './prompt-builder'
import { RouteSpot } from '../types/scenario'

describe('detectLanguage', () => {
  it('スポット名に日本語が含まれる場合は日本語を返す', () => {
    const spots: RouteSpot[] = [
      { name: '東京駅', type: 'start' },
      { name: 'Tokyo Tower', type: 'destination' }
    ]
    expect(detectLanguage(spots)).toBe('ja')
  })

  it('説明に日本語が含まれる場合は日本語を返す', () => {
    const spots: RouteSpot[] = [
      { name: 'Tokyo Station', type: 'start', description: '東京の中心部にある駅' }
    ]
    expect(detectLanguage(spots)).toBe('ja')
  })

  it('ポイントに日本語が含まれる場合は日本語を返す', () => {
    const spots: RouteSpot[] = [
      { name: 'Tokyo Station', type: 'start', point: '歴史的建造物' }
    ]
    expect(detectLanguage(spots)).toBe('ja')
  })

  it('日本語が含まれない場合は英語を返す', () => {
    const spots: RouteSpot[] = [
      { name: 'Tokyo Station', type: 'start', description: 'A major railway hub' },
      { name: 'Tokyo Tower', type: 'destination', point: 'Iconic landmark' }
    ]
    expect(detectLanguage(spots)).toBe('en')
  })

  it('空の配列の場合は英語を返す', () => {
    expect(detectLanguage([])).toBe('en')
  })

  it('ひらがなを検出する', () => {
    const spots: RouteSpot[] = [
      { name: 'とうきょう', type: 'start' }
    ]
    expect(detectLanguage(spots)).toBe('ja')
  })

  it('カタカナを検出する', () => {
    const spots: RouteSpot[] = [
      { name: 'トーキョー', type: 'start' }
    ]
    expect(detectLanguage(spots)).toBe('ja')
  })
})

describe('resolveLanguage', () => {
  const englishSpots: RouteSpot[] = [
    { name: 'Tokyo Station', type: 'start' }
  ]
  const japaneseSpots: RouteSpot[] = [
    { name: '東京駅', type: 'start' }
  ]

  it('言語が明示的に"ja"の場合はそのまま返す', () => {
    expect(resolveLanguage('ja', englishSpots)).toBe('ja')
  })

  it('言語が明示的に"en"の場合はそのまま返す', () => {
    expect(resolveLanguage('en', japaneseSpots)).toBe('en')
  })

  it('言語が"auto"の場合は入力から検出する', () => {
    expect(resolveLanguage('auto', englishSpots)).toBe('en')
    expect(resolveLanguage('auto', japaneseSpots)).toBe('ja')
  })

  it('言語がundefinedの場合は入力から検出する', () => {
    expect(resolveLanguage(undefined, englishSpots)).toBe('en')
    expect(resolveLanguage(undefined, japaneseSpots)).toBe('ja')
  })
})

describe('buildPrompt', () => {
  const routeName = 'Tokyo City Tour'
  const baseSpot: RouteSpot = {
    name: 'Tokyo Station',
    type: 'start',
    description: 'Historic railway station',
    point: 'Beautiful architecture'
  }

  describe('基本的なプロンプト生成', () => {
    it('ルート名が含まれる', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en')
      expect(prompt).toContain('Tokyo City Tour')
    })

    it('スポット名が含まれる', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en')
      expect(prompt).toContain('Tokyo Station')
    })

    it('説明が含まれる', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en')
      expect(prompt).toContain('Historic railway station')
    })

    it('ポイントが含まれる', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en')
      expect(prompt).toContain('Beautiful architecture')
    })
  })

  describe('スポットタイプ別コンテキスト - 英語', () => {
    it('startタイプは出発地点のコンテキストを含む', () => {
      const startSpot: RouteSpot = { ...baseSpot, type: 'start' }
      const prompt = buildPrompt(routeName, startSpot, 'en')
      expect(prompt).toContain('Starting Point')
      expect(prompt).toContain('warm welcome')
    })

    it('waypointタイプは経由地点のコンテキストを含む', () => {
      const waypointSpot: RouteSpot = { ...baseSpot, type: 'waypoint' }
      const prompt = buildPrompt(routeName, waypointSpot, 'en')
      expect(prompt).toContain('Waypoint')
      expect(prompt).toContain('Window View')
    })

    it('destinationタイプは目的地のコンテキストを含む', () => {
      const destSpot: RouteSpot = { ...baseSpot, type: 'destination' }
      const prompt = buildPrompt(routeName, destSpot, 'en')
      expect(prompt).toContain('Destination Arrival')
      expect(prompt).toContain('arrived')
    })

    it('不明なタイプはデフォルトコンテキストを含む', () => {
      const unknownSpot = { ...baseSpot, type: 'unknown' } as unknown as RouteSpot
      const prompt = buildPrompt(routeName, unknownSpot, 'en')
      expect(prompt).toContain('Sightseeing Point')
    })
  })

  describe('スポットタイプ別コンテキスト - 日本語', () => {
    it('startタイプは出発地点のコンテキストを含む', () => {
      const startSpot: RouteSpot = { ...baseSpot, type: 'start' }
      const prompt = buildPrompt(routeName, startSpot, 'ja')
      expect(prompt).toContain('出発地点')
      expect(prompt).toContain('歓迎')
    })

    it('waypointタイプは経由地点のコンテキストを含む', () => {
      const waypointSpot: RouteSpot = { ...baseSpot, type: 'waypoint' }
      const prompt = buildPrompt(routeName, waypointSpot, 'ja')
      expect(prompt).toContain('経由地点')
      expect(prompt).toContain('車窓')
    })

    it('destinationタイプは目的地のコンテキストを含む', () => {
      const destSpot: RouteSpot = { ...baseSpot, type: 'destination' }
      const prompt = buildPrompt(routeName, destSpot, 'ja')
      expect(prompt).toContain('目的地到着')
    })
  })

  describe('imagePromptオプション', () => {
    it('includeImagePrompt=trueの場合はJSON形式の指示が含まれる - 英語', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en', true)
      expect(prompt).toContain('imagePrompt')
      expect(prompt).toContain('JSON format')
      expect(prompt).toContain('scenario')
    })

    it('includeImagePrompt=trueの場合はJSON形式の指示が含まれる - 日本語', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'ja', true)
      expect(prompt).toContain('imagePrompt')
      expect(prompt).toContain('JSON形式')
      expect(prompt).toContain('scenario')
    })

    it('includeImagePrompt=falseの場合はシナリオのみを要求する', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en', false)
      expect(prompt).not.toContain('"imagePrompt"')
      expect(prompt).toContain('Output only the script')
    })

    it('デフォルトはincludeImagePrompt=false', () => {
      const prompt = buildPrompt(routeName, baseSpot, 'en')
      expect(prompt).not.toContain('"imagePrompt"')
    })
  })

  describe('オプションフィールドの処理', () => {
    it('descriptionがない場合も動作する', () => {
      const spot: RouteSpot = { name: 'Test', type: 'start' }
      const prompt = buildPrompt(routeName, spot, 'en')
      expect(prompt).toContain('Test')
      expect(prompt).not.toContain('Description: undefined')
    })

    it('pointがない場合も動作する', () => {
      const spot: RouteSpot = { name: 'Test', type: 'start' }
      const prompt = buildPrompt(routeName, spot, 'en')
      expect(prompt).toContain('Test')
      expect(prompt).not.toContain('Highlight: undefined')
    })
  })
})

describe('getSystemPrompt', () => {
  it('日本語のシステムプロンプトを返す', () => {
    const prompt = getSystemPrompt('ja')
    expect(prompt).toContain('タクシードライバー')
    expect(prompt).toContain('観光ガイド')
    expect(prompt).toContain('キャラクター設定')
  })

  it('英語のシステムプロンプトを返す', () => {
    const prompt = getSystemPrompt('en')
    expect(prompt).toContain('taxi driver')
    expect(prompt).toContain('tour guide')
    expect(prompt).toContain('Character Profile')
  })

  it('TTS向け最適化の注意点が含まれる - 日本語', () => {
    const prompt = getSystemPrompt('ja')
    expect(prompt).toContain('音声合成AI')
    expect(prompt).toContain('TTS')
  })

  it('TTS向け最適化の注意点が含まれる - 英語', () => {
    const prompt = getSystemPrompt('en')
    expect(prompt).toContain('text-to-speech')
    expect(prompt).toContain('TTS')
  })
})

describe('SYSTEM_PROMPT', () => {
  it('英語のシステムプロンプトと同じ内容', () => {
    expect(SYSTEM_PROMPT).toBe(getSystemPrompt('en'))
  })
})
