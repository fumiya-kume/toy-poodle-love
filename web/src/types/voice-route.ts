/**
 * 音声ルート検索に関する型定義
 */

/**
 * 会話から抽出された地点情報
 */
export interface ExtractedLocation {
  /** 出発地点 */
  origin: string | null;
  /** 目的地 */
  destination: string | null;
  /** 経由地点（オプション） */
  waypoints: string[];
  /** 抽出の信頼度（0-1） */
  confidence: number;
  /** LLMによる解釈の説明 */
  interpretation: string;
}

/**
 * 地点抽出APIのリクエスト
 */
export interface ExtractLocationRequest {
  /** 音声認識で得られたテキスト */
  text: string;
  /** 使用するLLMモデル */
  model?: 'qwen' | 'gemini';
}

/**
 * 地点抽出APIのレスポンス
 */
export interface ExtractLocationResponse {
  success: boolean;
  location?: ExtractedLocation;
  error?: string;
}

/**
 * 音声ルート検索のフルリクエスト
 */
export interface VoiceRouteSearchRequest {
  /** 音声認識テキスト */
  text: string;
  /** LLMモデル */
  model?: 'qwen' | 'gemini';
}

/**
 * 音声ルート検索のフルレスポンス
 */
export interface VoiceRouteSearchResponse {
  success: boolean;
  /** 抽出された地点情報 */
  extractedLocation?: ExtractedLocation;
  /** ジオコーディング結果 */
  geocodedPlaces?: {
    origin?: import('./place-route').GeocodedPlace;
    destination?: import('./place-route').GeocodedPlace;
    waypoints?: import('./place-route').GeocodedPlace[];
  };
  /** ルート最適化結果 */
  route?: {
    totalDistanceMeters: number;
    totalDurationSeconds: number;
    legs: import('./place-route').RouteLeg[];
  };
  error?: string;
}
