import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { GooglePlacesClient } from './google-places-client'

// グローバルfetchをモック
const mockFetch = vi.fn()
vi.stubGlobal('fetch', mockFetch)

describe('GooglePlacesClient', () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    vi.clearAllMocks()
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    consoleErrorSpy.mockRestore()
  })

  describe('constructor', () => {
    it('APIキーが渡されるとクライアントが初期化される', () => {
      const client = new GooglePlacesClient('test-api-key')
      expect(client).toBeInstanceOf(GooglePlacesClient)
    })

    it('APIキーがない場合はエラーをスローする', () => {
      expect(() => new GooglePlacesClient('')).toThrow('Google Maps API key is required')
    })

    it('APIキーがundefinedの場合はエラーをスローする', () => {
      expect(() => new GooglePlacesClient(undefined as unknown as string)).toThrow('Google Maps API key is required')
    })
  })

  describe('geocode', () => {
    let client: GooglePlacesClient

    beforeEach(() => {
      client = new GooglePlacesClient('test-api-key')
    })

    it('正常なレスポンスの場合はGeocodedPlaceを返す', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          places: [
            {
              id: 'place-id-123',
              formattedAddress: '東京都千代田区丸の内1丁目',
              location: {
                latitude: 35.6812,
                longitude: 139.7671
              },
              displayName: {
                text: '東京駅'
              }
            }
          ]
        })
      })

      const result = await client.geocode('東京駅')

      expect(result).toEqual({
        inputAddress: '東京駅',
        formattedAddress: '東京都千代田区丸の内1丁目',
        location: {
          latitude: 35.6812,
          longitude: 139.7671
        },
        placeId: 'place-id-123'
      })
    })

    it('正しいパラメータでfetchが呼ばれる', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          places: [{
            id: 'id',
            formattedAddress: 'address',
            location: { latitude: 0, longitude: 0 }
          }]
        })
      })

      await client.geocode('テスト住所')

      expect(mockFetch).toHaveBeenCalledWith(
        'https://places.googleapis.com/v1/places:searchText',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': 'test-api-key',
            'X-Goog-FieldMask': 'places.id,places.formattedAddress,places.location,places.displayName'
          },
          body: JSON.stringify({
            textQuery: 'テスト住所',
            maxResultCount: 1
          })
        }
      )
    })

    it('APIエラーの場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        text: async () => 'Bad Request'
      })

      await expect(client.geocode('テスト')).rejects.toThrow('Places API error: 400 - Bad Request')
    })

    it('結果が空の場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          places: []
        })
      })

      await expect(client.geocode('存在しない場所')).rejects.toThrow('No results found for address: 存在しない場所')
    })

    it('placesがundefinedの場合はエラーをスローする', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({})
      })

      await expect(client.geocode('テスト')).rejects.toThrow('No results found')
    })
  })

  describe('geocodeBatch', () => {
    let client: GooglePlacesClient

    beforeEach(() => {
      client = new GooglePlacesClient('test-api-key')
    })

    it('複数の住所を一括でジオコーディングする', async () => {
      mockFetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            places: [{
              id: 'id1',
              formattedAddress: 'Address 1',
              location: { latitude: 35.0, longitude: 139.0 }
            }]
          })
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            places: [{
              id: 'id2',
              formattedAddress: 'Address 2',
              location: { latitude: 34.0, longitude: 138.0 }
            }]
          })
        })

      const results = await client.geocodeBatch(['場所1', '場所2'])

      expect(results).toHaveLength(2)
      expect(results[0].inputAddress).toBe('場所1')
      expect(results[1].inputAddress).toBe('場所2')
    })

    it('一部失敗した場合は成功分のみを返す', async () => {
      mockFetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            places: [{
              id: 'id1',
              formattedAddress: 'Address 1',
              location: { latitude: 35.0, longitude: 139.0 }
            }]
          })
        })
        .mockResolvedValueOnce({
          ok: false,
          status: 404,
          text: async () => 'Not found'
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            places: [{
              id: 'id3',
              formattedAddress: 'Address 3',
              location: { latitude: 33.0, longitude: 137.0 }
            }]
          })
        })

      const results = await client.geocodeBatch(['場所1', '場所2', '場所3'])

      expect(results).toHaveLength(2)
      expect(results[0].inputAddress).toBe('場所1')
      expect(results[1].inputAddress).toBe('場所3')
    })

    it('すべて失敗した場合は空の配列を返す', async () => {
      mockFetch
        .mockResolvedValueOnce({
          ok: false,
          status: 500,
          text: async () => 'Server error'
        })
        .mockResolvedValueOnce({
          ok: false,
          status: 500,
          text: async () => 'Server error'
        })

      const results = await client.geocodeBatch(['場所1', '場所2'])

      expect(results).toHaveLength(0)
    })

    it('空の配列の場合は空の配列を返す', async () => {
      const results = await client.geocodeBatch([])

      expect(results).toHaveLength(0)
      expect(mockFetch).not.toHaveBeenCalled()
    })

    it('失敗したジオコーディングはエラーログを出力する', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        text: async () => 'Bad request'
      })

      await client.geocodeBatch(['失敗する場所'])

      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to geocode "失敗する場所":',
        expect.any(Error)
      )
    })
  })
})
