/**
 * Vitestグローバルセットアップ
 * 全テストで共有される設定
 */

import { vi, beforeEach, afterEach } from 'vitest'

// console出力を抑制（必要に応じて各テストでrestoreする）
beforeEach(() => {
  vi.spyOn(console, 'log').mockImplementation(() => {})
  vi.spyOn(console, 'warn').mockImplementation(() => {})
  vi.spyOn(console, 'error').mockImplementation(() => {})
})

afterEach(() => {
  vi.restoreAllMocks()
})
