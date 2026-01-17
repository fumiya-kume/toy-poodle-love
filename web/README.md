# Taxi Scenario Writer

QwenとGemini APIを呼び出す最小限のTypeScriptアプリケーション

## セットアップ

### 1. 依存関係のインストール

```bash
npm install
```

### 2. 環境変数の設定

`.env.example`ファイルを`.env`にコピーして、APIキーを設定します。

```bash
cp .env.example .env
```

`.env`ファイルを編集して、以下のAPIキーを設定してください:

```env
QWEN_API_KEY=your_qwen_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
```

### APIキーの取得方法

#### Qwen API Key
1. [Alibaba Cloud DashScope](https://dashscope.console.aliyun.com/)にアクセス
2. アカウントを作成してログイン
3. APIキーを生成

#### Gemini API Key
1. [Google AI Studio](https://makersuite.google.com/app/apikey)にアクセス
2. Googleアカウントでログイン
3. "Get API Key"をクリックしてキーを生成

## 使い方

### 開発モードで実行

```bash
npm run dev
```

### ビルドして実行

```bash
npm run build
npm start
```

## プロジェクト構成

```
taxi-senario-writer/
├── src/
│   ├── index.ts           # メインアプリケーション
│   ├── qwen-client.ts     # Qwen APIクライアント
│   └── gemini-client.ts   # Gemini APIクライアント
├── package.json
├── tsconfig.json
├── .env.example
├── .gitignore
└── README.md
```

## 使用しているモデル

- **Qwen**: `qwen-plus` (他のオプション: `qwen-turbo`, `qwen-max`)
- **Gemini**: `gemini-pro`

## ライセンス

ISC
# toy-story-love
# toy-story-love
