import os
import sys
import time
import requests
import json
import base64
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# API設定
API_KEY = os.environ.get("WAN_API_KEY")
API_BASE_URL = "https://dashscope-intl.aliyuncs.com/api/v1"

# WANパラメータ（.envから読み込み）
WAN_MODEL_I2V = os.environ.get("WAN_MODEL_I2V", "wan2.6-i2v")
WAN_MODEL_T2V = os.environ.get("WAN_MODEL_T2V", "wan2.6-t2v")
WAN_RESOLUTION = os.environ.get("WAN_RESOLUTION", "720P")  # I2V用: 480P, 720P, 1080P
WAN_SIZE = os.environ.get("WAN_SIZE", "1280*720")  # T2V用: 1920*1080, 1280*720, 832*480
WAN_DURATION = int(os.environ.get("WAN_DURATION", "10"))
WAN_AUDIO = os.environ.get("WAN_AUDIO", "true").lower() == "true"
WAN_PROMPT_EXTEND = os.environ.get("WAN_PROMPT_EXTEND", "true").lower() == "true"
WAN_SHOT_TYPE = os.environ.get("WAN_SHOT_TYPE", "single")
WAN_OUTPUT_DIR = os.environ.get("WAN_OUTPUT_DIR", "./output")


def encode_image_to_base64(image_path: str) -> str:
    """画像ファイルをBase64エンコードする"""
    ext = os.path.splitext(image_path)[1].lower()
    mime_types = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".gif": "image/gif",
        ".webp": "image/webp"
    }
    mime_type = mime_types.get(ext, "image/png")

    with open(image_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")

    return f"data:{mime_type};base64,{b64}"


def generate_video(prompt: str, image_input: str = None) -> dict:
    """
    WAN2.6 APIでビデオ生成リクエストを送信
    画像がある場合はI2V、ない場合はT2Vモードを使用

    Args:
        prompt: テキストプロンプト
        image_input: 画像URL、ローカルファイルパス、またはBase64データ（省略可）

    Returns:
        APIレスポンス（task_idを含む）
    """
    if not API_KEY:
        raise ValueError("WAN_API_KEY is not set in .env")

    url = f"{API_BASE_URL}/services/aigc/video-generation/video-synthesis"

    # 画像入力があるかどうかでI2V/T2Vを切り替え
    if image_input:
        # I2V (Image-to-Video) モード
        if os.path.exists(image_input):
            img_url = encode_image_to_base64(image_input)
            print(f"画像ファイルを読み込みました: {image_input}")
        elif image_input.startswith("data:"):
            img_url = image_input
        else:
            img_url = image_input

        payload = {
            "model": WAN_MODEL_I2V,
            "input": {
                "prompt": prompt,
                "img_url": img_url
            },
            "parameters": {
                "resolution": WAN_RESOLUTION,
                "prompt_extend": WAN_PROMPT_EXTEND,
                "duration": WAN_DURATION,
                "shot_type": WAN_SHOT_TYPE
            }
        }
        print(f"モード: I2V (Image-to-Video)")
    else:
        # T2V (Text-to-Video) モード
        payload = {
            "model": WAN_MODEL_T2V,
            "input": {
                "prompt": prompt
            },
            "parameters": {
                "size": WAN_SIZE,
                "prompt_extend": WAN_PROMPT_EXTEND,
                "duration": WAN_DURATION,
                "shot_type": WAN_SHOT_TYPE
            }
        }
        print(f"モード: T2V (Text-to-Video)")

    headers = {
        "X-DashScope-Async": "enable",
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    response = requests.post(url, headers=headers, json=payload)
    return response.json()


def check_status(task_id: str) -> dict:
    """
    タスクIDからリクエストの状況を確認

    Args:
        task_id: タスクID

    Returns:
        APIレスポンス（task_status, video_urlなど）
    """
    if not API_KEY:
        raise ValueError("WAN_API_KEY is not set in .env")

    url = f"{API_BASE_URL}/tasks/{task_id}"
    headers = {"Authorization": f"Bearer {API_KEY}"}

    response = requests.get(url, headers=headers)
    return response.json()


def wait_for_completion(task_id: str, interval: int = 10) -> dict:
    """
    10秒おきにステータスを確認し、完了まで待機

    Args:
        task_id: タスクID
        interval: 確認間隔（秒）

    Returns:
        完了時のAPIレスポンス
    """
    print(f"\nタスクID: {task_id}")
    print(f"{interval}秒おきにステータスを確認します...\n")

    while True:
        result = check_status(task_id)
        output = result.get("output", {})
        status = output.get("task_status", "UNKNOWN")

        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] ステータス: {status}")

        if status == "SUCCEEDED":
            print("\n[OK] 動画生成が完了しました!")
            return result
        elif status == "FAILED":
            error_msg = output.get("message", "不明なエラー")
            print(f"\n[ERROR] 生成失敗: {error_msg}")
            return result
        elif status not in ["PENDING", "RUNNING"]:
            print(f"\n[ERROR] 予期しないステータス: {status}")
            return result

        time.sleep(interval)


def download_video(video_url: str, output_path: str = None) -> str:
    """
    動画をローカルフォルダにダウンロード

    Args:
        video_url: 動画のURL
        output_path: 保存先パス（省略時は自動生成）

    Returns:
        保存したファイルパス
    """
    # 出力ディレクトリの作成
    os.makedirs(WAN_OUTPUT_DIR, exist_ok=True)

    if output_path is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = os.path.join(WAN_OUTPUT_DIR, f"wan_video_{timestamp}.mp4")

    print(f"\nダウンロード中: {video_url}")

    response = requests.get(video_url, stream=True)
    response.raise_for_status()

    with open(output_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)

    print(f"[OK] 保存完了: {output_path}")
    return output_path


def run(prompt: str, image_input: str = None) -> str:
    """
    メイン処理: 動画生成→待機→ダウンロード

    Args:
        prompt: テキストプロンプト
        image_input: 画像URL、ローカルファイルパス、またはBase64データ（省略可）

    Returns:
        ダウンロードした動画のパス
    """
    is_i2v = image_input is not None
    model = WAN_MODEL_I2V if is_i2v else WAN_MODEL_T2V
    resolution = WAN_RESOLUTION if is_i2v else WAN_SIZE

    print("=" * 50)
    print(f"WAN2.6 {'I2V' if is_i2v else 'T2V'} 動画生成")
    print("=" * 50)
    print(f"モデル: {model}")
    print(f"解像度: {resolution}")
    print(f"長さ: {WAN_DURATION}秒")
    print(f"プロンプト: {prompt}")
    if image_input:
        print(f"画像: {image_input}")
    print("=" * 50)

    # 1. 動画生成リクエスト
    print("\n動画生成をリクエスト中...")
    result = generate_video(prompt, image_input)

    if "output" not in result or "task_id" not in result.get("output", {}):
        print(f"エラー: {json.dumps(result, indent=2, ensure_ascii=False)}")
        return None

    task_id = result["output"]["task_id"]

    # 2. 完了まで待機
    final_result = wait_for_completion(task_id)

    # 3. 動画をダウンロード
    output = final_result.get("output", {})
    if output.get("task_status") == "SUCCEEDED":
        video_url = output.get("video_url")
        if video_url:
            return download_video(video_url)

    return None


def main():
    """コマンドライン実行用"""
    if len(sys.argv) < 2:
        print("使い方:")
        print("  T2V (テキストのみ):")
        print('    python wan_video.py "A cat walking slowly"')
        print()
        print("  I2V (画像+テキスト):")
        print('    python wan_video.py ./image.png "A cat walking slowly"')
        print('    python wan_video.py https://example.com/img.png "A beautiful sunset"')
        print()
        print("設定は .env ファイルで変更できます:")
        print("  WAN_MODEL_I2V, WAN_MODEL_T2V, WAN_RESOLUTION, WAN_SIZE,")
        print("  WAN_DURATION, WAN_PROMPT_EXTEND, WAN_SHOT_TYPE, WAN_OUTPUT_DIR")
        sys.exit(1)

    if len(sys.argv) == 2:
        # T2V: プロンプトのみ
        prompt = sys.argv[1]
        image_input = None
    else:
        # I2V: 画像 + プロンプト
        image_input = sys.argv[1]
        prompt = sys.argv[2]

    run(prompt, image_input)


if __name__ == "__main__":
    main()
