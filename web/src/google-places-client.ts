/**
 * Google Places API クライアント
 * 住所や場所名から緯度経度を取得する
 */

import { GeocodedPlace, LatLng } from './types/place-route';

interface PlacesTextSearchResponse {
  places?: Array<{
    id: string;
    formattedAddress: string;
    location: {
      latitude: number;
      longitude: number;
    };
    displayName?: {
      text: string;
    };
  }>;
}

export class GooglePlacesClient {
  private apiKey: string;
  private baseUrl = 'https://places.googleapis.com/v1/places:searchText';

  constructor(apiKey: string) {
    if (!apiKey) {
      throw new Error('Google Maps API key is required');
    }
    this.apiKey = apiKey;
  }

  /**
   * 住所や場所名から座標を取得
   */
  async geocode(address: string): Promise<GeocodedPlace> {
    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': this.apiKey,
        'X-Goog-FieldMask': 'places.id,places.formattedAddress,places.location,places.displayName',
      },
      body: JSON.stringify({
        textQuery: address,
        maxResultCount: 1,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Places API error: ${response.status} - ${errorText}`);
    }

    const data: PlacesTextSearchResponse = await response.json();

    if (!data.places || data.places.length === 0) {
      throw new Error(`No results found for address: ${address}`);
    }

    const place = data.places[0];

    return {
      inputAddress: address,
      formattedAddress: place.formattedAddress,
      location: {
        latitude: place.location.latitude,
        longitude: place.location.longitude,
      },
      placeId: place.id,
    };
  }

  /**
   * 複数の住所/場所名を一括でジオコーディング
   */
  async geocodeBatch(addresses: string[]): Promise<GeocodedPlace[]> {
    const results = await Promise.all(
      addresses.map(async (address) => {
        try {
          return await this.geocode(address);
        } catch (error) {
          // 個別のエラーは null として返し、後で除外
          console.error(`Failed to geocode "${address}":`, error);
          return null;
        }
      })
    );

    // null を除外して返す
    return results.filter((result): result is GeocodedPlace => result !== null);
  }
}
