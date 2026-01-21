# Alibaba Cloud ARMS LLMOps セットアップガイド

このドキュメントでは、Alibaba Cloud ARMS (Application Real-Time Monitoring Service) を使用してLLMアプリケーションの監視（LLMOps）を設定する方法を説明します。

## 概要

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Application   │────▶│   OpenTelemetry │────▶│   ARMS Console  │
│  (Qwen/Gemini)  │     │   + OpenLLMetry │     │   (Dashboard)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 収集されるデータ

- **LLM入力（プロンプト）**: ユーザーからの入力テキスト
- **LLM出力（レスポンス）**: モデルからの応答テキスト
- **トークン使用量**: 入力トークン数、出力トークン数、合計トークン数
- **レイテンシ**: API呼び出しにかかった時間
- **エラー情報**: 発生したエラーの詳細

## 前提条件

1. Alibaba Cloudアカウント
2. ARMSサービスの有効化
3. Node.js 18以上

## セットアップ手順

### 1. ARMSアプリケーションの作成

1. [ARMS Console](https://arms.console.aliyun.com/) にログイン
2. **アプリケーション監視** > **アプリケーション一覧** に移動
3. **アプリケーション作成** をクリック
4. 以下を設定:
   - アプリケーション名: `taxi-scenario-writer`
   - アプリケーションタイプ: `カスタム`
   - データ収集方式: `OpenTelemetry`

### 2. OTLPエンドポイントの取得

ARMSコンソールで作成したアプリケーションの詳細から、OTLPエンドポイントを確認します：

```
http://<region>.arms.aliyuncs.com:8090/api/otlp/traces
```

リージョン例:
- 中国（杭州）: `cn-hangzhou`
- 中国（上海）: `cn-shanghai`
- シンガポール: `ap-southeast-1`
- シリコンバレー: `us-west-1`

### 3. 環境変数の設定

`.env` ファイルに以下を追加:

```bash
# ARMS LLMOps Configuration
ARMS_ENDPOINT=http://cn-hangzhou.arms.aliyuncs.com:8090/api/otlp/traces
ARMS_AUTH_TOKEN=your_auth_token_here  # 必要な場合
OTEL_SERVICE_NAME=taxi-scenario-writer
ARMS_TRACING_DISABLED=false
```

### 4. アプリケーションの起動

```bash
npm run cli
```

## アーキテクチャ

### 自動計装（Qwen）

Qwenクライアントは OpenAI SDK互換のため、OpenLLMetry が自動的にトレースを収集します：

```typescript
// qwen-client.ts - 変更不要
this.client = new OpenAI({
  apiKey,
  baseURL: 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
});
```

### 手動計装（Gemini）

Google Gemini API は手動でトレースを追加しています：

```typescript
// gemini-client.ts
import { traceLLMCall } from './telemetry';

async chat(message: string): Promise<string> {
  return traceLLMCall(
    {
      provider: 'google',
      model: 'gemini-2.5-flash-lite',
      operation: 'chat',
    },
    message,
    async (span) => {
      const result = await this.chatInternal(message);
      return {
        content: result.content,
        promptTokens: result.promptTokens,
        completionTokens: result.completionTokens,
      };
    }
  ).then((result) => result.content);
}
```

## ARMSダッシュボードでの確認

### 1. トレースの確認

1. ARMS Console > **トレース分析** に移動
2. サービス名 `taxi-scenario-writer` でフィルタ
3. 各トレースをクリックして詳細を確認

### 2. LLM固有のメトリクス

トレース詳細で以下の属性を確認できます：

| 属性名 | 説明 |
|--------|------|
| `gen_ai.system` | LLMプロバイダー（google, qwen等） |
| `gen_ai.request.model` | 使用したモデル名 |
| `gen_ai.prompt` | 入力プロンプト |
| `gen_ai.completion` | モデルの応答 |
| `gen_ai.usage.input_tokens` | 入力トークン数 |
| `gen_ai.usage.output_tokens` | 出力トークン数 |
| `gen_ai.usage.total_tokens` | 合計トークン数 |
| `llm.latency_ms` | レスポンス時間（ミリ秒） |

### 3. アラートの設定

1. ARMS Console > **アラート管理** に移動
2. 新規アラートルールを作成:
   - 条件: `llm.latency_ms > 30000` （30秒以上）
   - 条件: `error_rate > 0.1` （エラー率10%以上）

## カスタム計装の追加

新しいLLMクライアントを追加する場合：

```typescript
import { traceLLMCall, startLLMSpan } from './telemetry';

// 方法1: traceLLMCall を使用
const result = await traceLLMCall(
  { provider: 'anthropic', model: 'claude-3-opus' },
  prompt,
  async (span) => {
    const response = await anthropicClient.messages.create({ ... });
    return {
      content: response.content[0].text,
      promptTokens: response.usage.input_tokens,
      completionTokens: response.usage.output_tokens,
    };
  }
);

// 方法2: 手動スパン管理
const { span, end } = startLLMSpan('anthropic.chat', {
  provider: 'anthropic',
  model: 'claude-3-opus',
});
try {
  // ... API呼び出し
  span.setAttribute('gen_ai.completion', response);
} finally {
  end();
}
```

## トラブルシューティング

### トレースが表示されない

1. `ARMS_ENDPOINT` が正しく設定されているか確認
2. `ARMS_TRACING_DISABLED=false` になっているか確認
3. ネットワーク接続を確認（ARMSエンドポイントへのアクセス）

### 認証エラー

1. `ARMS_AUTH_TOKEN` が正しいか確認
2. ARMSコンソールでアプリケーションの権限を確認

### ログでの確認

起動時に以下のログが出力されます：

```
Initializing ARMS LLMOps tracing: {
  endpoint: 'http://cn-hangzhou.arms.aliyuncs.com:8090/api/otlp/traces',
  serviceName: 'taxi-scenario-writer',
  environment: 'development',
  hasAuthToken: true
}
ARMS LLMOps tracing initialized successfully
```

## 参考リンク

- [ARMS Documentation](https://www.alibabacloud.com/help/arms)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [OpenLLMetry by Traceloop](https://github.com/traceloop/openllmetry-js)
- [ARMS OpenTelemetry Integration](https://www.alibabacloud.com/help/arms/opentelemetry)
