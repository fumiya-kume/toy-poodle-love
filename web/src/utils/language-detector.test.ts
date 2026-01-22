import { describe, it, expect } from 'vitest'
import { detectLanguage, detectLanguageFromTexts } from './language-detector'

describe('detectLanguage', () => {
  describe('日本語の検出', () => {
    it('空文字の場合はデフォルトで日本語を返す', () => {
      expect(detectLanguage('')).toBe('ja')
    })

    it('空白のみの場合は日本語を返す', () => {
      expect(detectLanguage('   ')).toBe('ja')
      expect(detectLanguage('\t\n')).toBe('ja')
    })

    it('ひらがなを含む場合は日本語を返す', () => {
      expect(detectLanguage('こんにちは')).toBe('ja')
      expect(detectLanguage('ありがとう')).toBe('ja')
    })

    it('カタカナを含む場合は日本語を返す', () => {
      expect(detectLanguage('トウキョウ')).toBe('ja')
      expect(detectLanguage('カタカナ')).toBe('ja')
    })

    it('漢字のみの場合は日本語を返す', () => {
      expect(detectLanguage('東京駅')).toBe('ja')
      expect(detectLanguage('京都')).toBe('ja')
    })

    it('ひらがな・カタカナと英語の混合は日本語を返す', () => {
      expect(detectLanguage('Hello こんにちは')).toBe('ja')
      expect(detectLanguage('Tokyo タワー')).toBe('ja')
    })
  })

  describe('英語の検出', () => {
    it('アルファベットのみの場合は英語を返す', () => {
      expect(detectLanguage('Hello World')).toBe('en')
      expect(detectLanguage('Tokyo Station')).toBe('en')
    })

    it('アルファベットと数字の場合は英語を返す', () => {
      expect(detectLanguage('Route 66')).toBe('en')
      expect(detectLanguage('Platform 9')).toBe('en')
    })
  })

  describe('漢字とアルファベットの混合', () => {
    it('漢字とアルファベットの混合は英語を返す', () => {
      // 漢字のみ（仮名なし）でアルファベットがある場合は英語
      expect(detectLanguage('東京 Station')).toBe('en')
    })
  })

  describe('境界ケース', () => {
    it('数字のみの場合は日本語を返す（デフォルト）', () => {
      expect(detectLanguage('12345')).toBe('ja')
    })

    it('記号のみの場合は日本語を返す（デフォルト）', () => {
      expect(detectLanguage('!@#$%')).toBe('ja')
    })

    it('Unicode境界: ひらがなの範囲 (U+3040-U+309F)', () => {
      expect(detectLanguage('\u3040')).toBe('ja') // ひらがな開始
      expect(detectLanguage('\u309F')).toBe('ja') // ひらがな終了
    })

    it('Unicode境界: カタカナの範囲 (U+30A0-U+30FF)', () => {
      expect(detectLanguage('\u30A0')).toBe('ja') // カタカナ開始
      expect(detectLanguage('\u30FF')).toBe('ja') // カタカナ終了
    })

    it('Unicode境界: CJK漢字の範囲 (U+4E00-U+9FFF)', () => {
      expect(detectLanguage('\u4E00')).toBe('ja') // CJK開始
      expect(detectLanguage('\u9FFF')).toBe('ja') // CJK終了
    })
  })
})

describe('detectLanguageFromTexts', () => {
  it('複数のテキストを結合して言語を検出する', () => {
    expect(detectLanguageFromTexts(['Hello', 'World'])).toBe('en')
    expect(detectLanguageFromTexts(['こんにちは', '世界'])).toBe('ja')
  })

  it('ひらがな・カタカナと英語の混合は日本語を返す', () => {
    // ひらがな・カタカナが含まれる場合は日本語
    expect(detectLanguageFromTexts(['Hello', 'こんにちは'])).toBe('ja')
    expect(detectLanguageFromTexts(['Tokyo', 'トーキョー'])).toBe('ja')
  })

  it('漢字とアルファベットの混合は英語を返す', () => {
    // 漢字のみ（仮名なし）でアルファベットがある場合は英語
    expect(detectLanguageFromTexts(['Tokyo', '大阪'])).toBe('en')
  })

  it('空の配列は日本語を返す', () => {
    expect(detectLanguageFromTexts([])).toBe('ja')
  })

  it('undefinedを含む配列はフィルタリングされる', () => {
    expect(detectLanguageFromTexts([undefined, 'Hello', undefined])).toBe('en')
    expect(detectLanguageFromTexts([undefined, 'こんにちは', undefined])).toBe('ja')
  })

  it('空文字を含む配列はフィルタリングされる', () => {
    expect(detectLanguageFromTexts(['', 'Hello', ''])).toBe('en')
    expect(detectLanguageFromTexts(['', '  ', 'こんにちは'])).toBe('ja')
  })

  it('すべてundefinedまたは空文字の場合は日本語を返す', () => {
    expect(detectLanguageFromTexts([undefined, undefined])).toBe('ja')
    expect(detectLanguageFromTexts(['', '  ', ''])).toBe('ja')
  })
})
