# WAN2.6 Video Generator

Alibaba Cloud WAN2.6 APIを使用した動画生成ツールです。テキストのみ（T2V）または画像+テキスト（I2V）から動画を生成できます。

## セットアップ

### 1. 依存関係のインストール

```bash
pip install -r requirements.txt
```

### 2. 環境変数の設定

`.env.example`をコピーして`.env`を作成し、APIキーを設定してください。

```bash
cp .env.example .env
```

APIキーは[Alibaba Cloud Model Studio](https://www.alibabacloud.com/product/model-studio)から取得できます。

## 使い方

### T2V（テキストから動画生成）

画像なしでテキストプロンプトのみから動画を生成します。

```bash
python wan_video.py "A cute toy poodle running in a sunny park"
```

### I2V（画像から動画生成）

画像とテキストプロンプトから動画を生成します。

```bash
# ローカル画像
python wan_video.py ./image.png "A cat walking slowly"

# URL
python wan_video.py https://example.com/image.jpg "A beautiful sunset"
```

## 設定オプション

`.env`ファイルで以下のパラメータを設定できます。

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `WAN_API_KEY` | Alibaba Cloud APIキー（必須） | - |
| `WAN_MODEL_I2V` | I2Vモデル名 | `wan2.6-i2v` |
| `WAN_MODEL_T2V` | T2Vモデル名 | `wan2.6-t2v` |
| `WAN_RESOLUTION` | I2V解像度 (`480P`, `720P`, `1080P`) | `720P` |
| `WAN_SIZE` | T2V解像度 (`1920*1080`, `1280*720`, `832*480`) | `1280*720` |
| `WAN_DURATION` | 動画の長さ（秒）: 5, 10, 15 | `10` |
| `WAN_PROMPT_EXTEND` | LLMによるプロンプト拡張 | `true` |
| `WAN_SHOT_TYPE` | ショットタイプ (`single`, `multi`) | `single` |
| `WAN_OUTPUT_DIR` | 出力ディレクトリ | `./output` |

## 出力

生成された動画は`WAN_OUTPUT_DIR`（デフォルト: `./output`）に保存されます。

ファイル名: `wan_video_YYYYMMDD_HHMMSS.mp4`

## 注意事項

- 動画生成には通常1〜5分かかります
- APIの動画URLは24時間で期限切れになります（自動でダウンロードされます）
- 対応画像形式: JPEG, PNG, BMP, WEBP（360-2000px, 最大10MB）

## 参考リンク

- [WAN Text-to-Video API Reference](https://www.alibabacloud.com/help/en/model-studio/text-to-video-api-reference)
- [WAN Image-to-Video API Reference](https://www.alibabacloud.com/help/en/model-studio/image-to-video-api-reference)
