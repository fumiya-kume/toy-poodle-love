/**
 * Google Places API と Routes API に関する型定義
 */

/**
 * 緯度経度の座標
 */
export interface LatLng {
  latitude: number;
  longitude: number;
}

/**
 * ジオコーディング結果（住所から座標を取得）
 */
export interface GeocodedPlace {
  /** 入力された住所/場所名 */
  inputAddress: string;
  /** 元のスポット名（iOS側のキャッシュキーとして使用） */
  spotName?: string;
  /** 正規化された住所（Google が返す形式） */
  formattedAddress: string;
  /** 座標 */
  location: LatLng;
  /** Place ID（Google の一意識別子） */
  placeId: string;
}

/**
 * ジオコーディングリクエスト
 */
export interface GeocodeRequest {
  /** ジオコーディングする住所/場所名のリスト */
  addresses: string[];
}

/**
 * ジオコーディングレスポンス
 */
export interface GeocodeResponse {
  success: boolean;
  /** ジオコーディング結果 */
  places?: GeocodedPlace[];
  /** エラーメッセージ */
  error?: string;
}

/**
 * ルート最適化の入力地点
 */
export interface RouteWaypoint {
  /** 地点名（任意、識別用） */
  name?: string;
  /** Place ID または座標 */
  placeId?: string;
  location?: LatLng;
  /** 住所（placeId も location もない場合に使用） */
  address?: string;
}

/**
 * ルート最適化リクエスト
 */
export interface RouteOptimizationRequest {
  /** 出発地点 */
  origin: RouteWaypoint;
  /** 目的地（最終地点） */
  destination: RouteWaypoint;
  /** 経由地点（順序を最適化する対象） */
  intermediates: RouteWaypoint[];
  /** 移動モード */
  travelMode?: 'DRIVE' | 'WALK' | 'BICYCLE' | 'TRANSIT';
  /** 経由地点の順序を最適化するか */
  optimizeWaypointOrder?: boolean;
}

/**
 * 最適化されたルートの地点情報
 */
export interface OptimizedWaypoint {
  /** 元の入力でのインデックス */
  originalIndex: number;
  /** 最適化後の順序 */
  optimizedOrder: number;
  /** 地点情報 */
  waypoint: RouteWaypoint;
}

/**
 * ルート区間の情報
 */
export interface RouteLeg {
  /** 区間の開始地点インデックス */
  fromIndex: number;
  /** 区間の終了地点インデックス */
  toIndex: number;
  /** 距離（メートル） */
  distanceMeters: number;
  /** 所要時間（秒） */
  durationSeconds: number;
}

/**
 * ルート最適化レスポンス
 */
export interface RouteOptimizationResponse {
  success: boolean;
  /** 最適化されたルート */
  optimizedRoute?: {
    /** 最適化された地点の順序 */
    orderedWaypoints: OptimizedWaypoint[];
    /** 各区間の情報 */
    legs: RouteLeg[];
    /** 総距離（メートル） */
    totalDistanceMeters: number;
    /** 総所要時間（秒） */
    totalDurationSeconds: number;
  };
  /** エラーメッセージ */
  error?: string;
}
