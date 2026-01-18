import { NextRequest, NextResponse } from 'next/server';
import { GooglePlacesClient } from '../../../../src/google-places-client';
import { GeocodeRequest, GeocodeResponse } from '../../../../src/types/place-route';

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

    // 環境変数からAPIキーを取得
    const googleApiKey = process.env.GOOGLE_MAPS_API_KEY;

    if (!googleApiKey) {
      return NextResponse.json<GeocodeResponse>(
        {
          success: false,
          error: 'GOOGLE_MAPS_API_KEYが設定されていません',
        },
        { status: 500 }
      );
    }

    // ジオコーディング実行
    const client = new GooglePlacesClient(googleApiKey);
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
