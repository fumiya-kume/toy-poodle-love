import { NextRequest, NextResponse } from 'next/server';
import { GooglePlacesClient } from '../../../../src/google-places-client';
import { GeocodeRequest, GeocodeResponse } from '../../../../src/types/place-route';
import { getEnv, requireApiKey } from '../../../../src/config';

export async function POST(request: NextRequest) {
  try {
    const body: GeocodeRequest = await request.json();
    const { addresses } = body;

    // バリデーション
    if (!addresses || !Array.isArray(addresses) || addresses.length === 0) {
      return NextResponse.json<GeocodeResponse>(
        {
          success: false,
          error: 'addresses配列が必要です',
        },
        { status: 400 }
      );
    }

    const keyError = requireApiKey('googleMaps');
    if (keyError) return keyError;

    const env = getEnv();

    // ジオコーディング実行
    const client = new GooglePlacesClient(env.googleMapsApiKey!);
    const places = await client.geocodeBatch(addresses);

    return NextResponse.json<GeocodeResponse>({
      success: true,
      places,
    });
  } catch (error) {
    console.error('ジオコーディングエラー:', error);
    return NextResponse.json<GeocodeResponse>(
      {
        success: false,
        error: error instanceof Error ? error.message : 'ジオコーディングに失敗しました',
      },
      { status: 500 }
    );
  }
}
