/**
 * タクシールートとシナリオに関する型定義
 */

/**
 * 地点のタイプ
 */
export type SpotType = 'start' | 'waypoint' | 'destination';

/**
 * ルート上の地点情報
 */
export interface RouteSpot {
  /** 地点名 */
  name: string;
  /** 住所（ジオコーディング用） */
  address?: string;
  /** 地点タイプ */
  type: SpotType;
  /** 地点の説明・特徴 */
  description?: string;
  /** 観光ポイント */
  point?: string;
}

/**
 * 出力言語
 */
export type OutputLanguage = 'ja' | 'en' | 'auto';

/**
 * タクシールート全体の入力データ
 */
export interface RouteInput {
  /** ルート名 */
  routeName: string;
  /** 地点リスト */
  spots: RouteSpot[];
  /** 出力言語（省略時はauto: 入力から自動検出） */
  language?: OutputLanguage;
}

/**
 * 生成されたシナリオ（地点ごと）
 */
export interface SpotScenario {
  /** 地点名 */
  name: string;
  /** 地点タイプ */
  type: SpotType;
  /** Qwenによる生成結果 */
  qwen?: string;
  /** Geminiによる生成結果 */
  gemini?: string;
  /** エラーメッセージ（失敗時） */
  error?: {
    qwen?: string;
    gemini?: string;
  };
}

/**
 * 統計情報
 */
export interface ScenarioStats {
  /** 総地点数 */
  totalSpots: number;
  /** 成功数 */
  successCount: {
    qwen: number;
    gemini: number;
  };
  /** 処理時間（ミリ秒） */
  processingTimeMs: number;
}

/**
 * シナリオ生成の最終出力
 */
export interface ScenarioOutput {
  /** 生成日時 */
  generatedAt: string;
  /** ルート名 */
  routeName: string;
  /** 各地点のシナリオ */
  spots: SpotScenario[];
  /** 統計情報 */
  stats: ScenarioStats;
}

/**
 * モデル選択
 */
export type ModelSelection = 'qwen' | 'gemini' | 'both';

/**
 * シナリオ統合の入力データ
 */
export interface ScenarioIntegrationInput {
  /** ルート名 */
  routeName: string;
  /** 統合する地点のシナリオ */
  spots: SpotScenario[];
  /** どのモデルの結果を使用するか */
  sourceModel: 'qwen' | 'gemini';
  /** 統合処理に使用するLLM（省略時はsourceModelと異なる方） */
  integrationLLM?: 'qwen' | 'gemini';
}

/**
 * シナリオ統合の出力データ
 */
export interface ScenarioIntegrationOutput {
  /** 統合日時 */
  integratedAt: string;
  /** ルート名 */
  routeName: string;
  /** ソースとして使用したモデル */
  sourceModel: 'qwen' | 'gemini';
  /** 統合処理に使用したLLM */
  integrationLLM: 'qwen' | 'gemini';
  /** 統合されたシナリオテキスト */
  integratedScript: string;
  /** 処理時間（ミリ秒） */
  processingTimeMs: number;
}
