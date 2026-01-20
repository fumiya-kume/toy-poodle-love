/**
 * DashScope リアルタイム音声認識 WebSocket クライアント
 *
 * Qwen-ASR-Realtime モデルを使用したリアルタイム音声認識を提供
 * WebSocketプロトコルで音声データをストリーミング送信し、
 * リアルタイムで認識結果を受信
 *
 * 参考: https://www.alibabacloud.com/help/en/model-studio/qwen-real-time-speech-recognition
 */

import WebSocket from 'ws';

// Qwen-ASR-Realtime用の型定義
export type QwenAsrModel = 'qwen3-asr-flash-realtime' | 'qwen3-asr-flash-realtime-2025-10-27';

export interface SpeechRecognitionConfig {
  model?: QwenAsrModel;
  sampleRate?: number;
  language?: string;
  // VADモード設定 (nullでManualモード)
  turnDetection?: {
    type: 'server_vad';
    threshold?: number;
    prefix_padding_ms?: number;
    silence_duration_ms?: number;
  } | null;
}

export interface SpeechRecognitionCallbacks {
  onSessionCreated?: (sessionId: string) => void;
  onTranscriptionText?: (text: string, isPartial: boolean) => void;
  onTranscriptionCompleted?: (text: string) => void;
  onError?: (error: Error | { code: string; message: string }) => void;
  onConnectionClosed?: () => void;
}

export type ClientState =
  | 'disconnected'
  | 'connecting'
  | 'connected'
  | 'running'
  | 'finishing'
  | 'closed';

// デフォルト設定
const DEFAULT_CONFIG: Required<Omit<SpeechRecognitionConfig, 'turnDetection' | 'language'>> = {
  model: 'qwen3-asr-flash-realtime',
  sampleRate: 16000,
};

// Qwen-ASR-Realtime イベントタイプ
interface SessionUpdateEvent {
  type: 'session.update';
  session: {
    modalities?: string[];
    input_audio_format?: string;
    sample_rate?: number;
    input_audio_transcription?: {
      language?: string;
    };
    turn_detection?: {
      type: 'server_vad';
      threshold?: number;
      prefix_padding_ms?: number;
      silence_duration_ms?: number;
    } | null;
  };
}

interface InputAudioBufferAppendEvent {
  type: 'input_audio_buffer.append';
  audio: string; // Base64エンコード
}

interface InputAudioBufferCommitEvent {
  type: 'input_audio_buffer.commit';
}

interface SessionFinishEvent {
  type: 'session.finish';
}

// サーバーレスポンスイベント
interface ServerEvent {
  type: string;
  [key: string]: unknown;
}

interface SessionCreatedEvent extends ServerEvent {
  type: 'session.created';
  session: {
    id: string;
  };
}

interface TranscriptionTextEvent extends ServerEvent {
  type: 'conversation.item.input_audio_transcription.text';
  text: string;
}

interface TranscriptionCompletedEvent extends ServerEvent {
  type: 'conversation.item.input_audio_transcription.completed';
  transcript: string;
}

interface ErrorEvent extends ServerEvent {
  type: 'error';
  error: {
    code: string;
    message: string;
  };
}

export class SpeechRecognitionClient {
  private apiKey: string;
  private region: 'china' | 'international';
  private ws: WebSocket | null = null;
  private sessionId: string | null = null;
  private state: ClientState = 'disconnected';
  private config: SpeechRecognitionConfig;
  private callbacks: SpeechRecognitionCallbacks = {};

  constructor(
    apiKey: string,
    region: 'china' | 'international' = 'international',
    config: SpeechRecognitionConfig = {}
  ) {
    this.apiKey = apiKey;
    this.region = region;
    this.config = { ...DEFAULT_CONFIG, ...config };

    console.log('SpeechRecognitionClient initialized:', {
      region,
      model: this.config.model,
      sampleRate: this.config.sampleRate,
      hasApiKey: !!apiKey,
    });
  }

  /**
   * WebSocketエンドポイントURLを取得
   */
  private getWebSocketUrl(): string {
    const model = this.config.model || DEFAULT_CONFIG.model;
    const baseUrl = this.region === 'china'
      ? 'wss://dashscope.aliyuncs.com'
      : 'wss://dashscope-intl.aliyuncs.com';

    return `${baseUrl}/api-ws/v1/realtime?model=${model}`;
  }

  /**
   * 現在の状態を取得
   */
  getState(): ClientState {
    return this.state;
  }

  /**
   * セッションIDを取得
   */
  getSessionId(): string | null {
    return this.sessionId;
  }

  /**
   * コールバックを設定
   */
  setCallbacks(callbacks: SpeechRecognitionCallbacks): void {
    this.callbacks = callbacks;
  }

  /**
   * WebSocket接続を開始
   */
  async connect(): Promise<void> {
    if (this.state !== 'disconnected') {
      throw new Error(`Cannot connect: current state is ${this.state}`);
    }

    this.state = 'connecting';

    const url = this.getWebSocketUrl();
    console.log('Connecting to WebSocket:', {
      url,
      timestamp: new Date().toISOString(),
    });

    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(url, {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
          },
        });

        const connectionTimeout = setTimeout(() => {
          if (this.state === 'connecting') {
            this.ws?.close();
            this.state = 'disconnected';
            reject(new Error('WebSocket connection timeout (30s)'));
          }
        }, 30000);

        this.ws.on('open', () => {
          console.log('WebSocket connection opened');
          clearTimeout(connectionTimeout);
          this.state = 'connected';
          // セッション設定を送信
          this.sendSessionUpdate();
        });

        this.ws.on('message', (data: Buffer) => {
          this.handleMessage(data, resolve, reject);
        });

        this.ws.on('error', (error) => {
          console.error('WebSocket error:', error);
          clearTimeout(connectionTimeout);
          this.state = 'disconnected';
          this.callbacks.onError?.(error instanceof Error ? error : new Error(String(error)));
          reject(error);
        });

        this.ws.on('close', (code, reason) => {
          console.log('WebSocket connection closed:', { code, reason: reason.toString() });
          this.state = 'closed';
          this.callbacks.onConnectionClosed?.();
        });
      } catch (error) {
        this.state = 'disconnected';
        reject(error);
      }
    });
  }

  /**
   * session.updateを送信してセッションを設定
   */
  private sendSessionUpdate(): void {
    if (!this.ws) {
      throw new Error('WebSocket not connected');
    }

    const sampleRate = this.config.sampleRate || DEFAULT_CONFIG.sampleRate;

    const sessionUpdate: SessionUpdateEvent = {
      type: 'session.update',
      session: {
        modalities: ['text'],
        input_audio_format: 'pcm',
        sample_rate: sampleRate,
        input_audio_transcription: this.config.language
          ? { language: this.config.language }
          : undefined,
        // ManualモードはturnDetectionをnullに設定
        turn_detection: this.config.turnDetection === undefined
          ? null // デフォルトはManualモード
          : this.config.turnDetection,
      },
    };

    console.log('Sending session.update:', JSON.stringify(sessionUpdate, null, 2));
    this.ws.send(JSON.stringify(sessionUpdate));
  }

  /**
   * サーバーからのメッセージを処理
   */
  private handleMessage(
    data: Buffer,
    connectResolve?: (value: void | PromiseLike<void>) => void,
    connectReject?: (reason?: Error) => void
  ): void {
    try {
      const message = JSON.parse(data.toString()) as ServerEvent;
      const eventType = message.type;

      console.log('Received event:', eventType, JSON.stringify(message, null, 2));

      switch (eventType) {
        case 'session.created': {
          const event = message as SessionCreatedEvent;
          this.sessionId = event.session.id;
          this.state = 'running';
          this.callbacks.onSessionCreated?.(event.session.id);
          connectResolve?.();
          break;
        }

        case 'session.updated': {
          // セッション更新完了
          console.log('Session updated');
          break;
        }

        case 'conversation.item.input_audio_transcription.text': {
          const event = message as TranscriptionTextEvent;
          this.callbacks.onTranscriptionText?.(event.text, true);
          break;
        }

        case 'conversation.item.input_audio_transcription.completed': {
          const event = message as TranscriptionCompletedEvent;
          this.callbacks.onTranscriptionText?.(event.transcript, false);
          this.callbacks.onTranscriptionCompleted?.(event.transcript);
          break;
        }

        case 'input_audio_buffer.speech_started': {
          console.log('Speech started (VAD detected)');
          break;
        }

        case 'input_audio_buffer.speech_stopped': {
          console.log('Speech stopped (VAD detected)');
          break;
        }

        case 'input_audio_buffer.committed': {
          console.log('Audio buffer committed');
          break;
        }

        case 'error': {
          const event = message as ErrorEvent;
          console.error('Server error:', event.error);
          this.callbacks.onError?.(event.error);
          connectReject?.(new Error(`${event.error.code}: ${event.error.message}`));
          break;
        }

        case 'session.finished': {
          console.log('Session finished');
          this.state = 'closed';
          this.ws?.close();
          break;
        }

        default:
          console.log('Unhandled event type:', eventType);
      }
    } catch (error) {
      console.error('Failed to parse message:', error);
      this.callbacks.onError?.(error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 音声データを送信
   * @param audioData PCM16形式の音声バイナリデータ
   */
  sendAudio(audioData: Buffer | Uint8Array): void {
    if (this.state !== 'running') {
      throw new Error(`Cannot send audio: current state is ${this.state}. Wait for session.created event.`);
    }

    if (!this.ws) {
      throw new Error('WebSocket not connected');
    }

    // Base64エンコードして送信
    const base64Audio = Buffer.from(audioData).toString('base64');

    const appendEvent: InputAudioBufferAppendEvent = {
      type: 'input_audio_buffer.append',
      audio: base64Audio,
    };

    this.ws.send(JSON.stringify(appendEvent));
  }

  /**
   * 音声バッファをコミット（Manualモード用）
   */
  commitAudio(): void {
    if (this.state !== 'running') {
      console.warn(`Cannot commit: current state is ${this.state}`);
      return;
    }

    if (!this.ws) {
      throw new Error('WebSocket not connected');
    }

    const commitEvent: InputAudioBufferCommitEvent = {
      type: 'input_audio_buffer.commit',
    };

    console.log('Sending input_audio_buffer.commit');
    this.ws.send(JSON.stringify(commitEvent));
  }

  /**
   * セッションを終了
   */
  async finish(): Promise<void> {
    if (this.state !== 'running') {
      console.warn(`Cannot finish: current state is ${this.state}`);
      return;
    }

    if (!this.ws) {
      throw new Error('WebSocket not connected');
    }

    this.state = 'finishing';

    // まず音声バッファをコミット
    this.commitAudio();

    // セッション終了を送信
    const finishEvent: SessionFinishEvent = {
      type: 'session.finish',
    };

    console.log('Sending session.finish');
    this.ws.send(JSON.stringify(finishEvent));

    // session.finishedイベントを待つ
    return new Promise((resolve) => {
      const checkClosed = setInterval(() => {
        if (this.state === 'closed' || this.state === 'disconnected') {
          clearInterval(checkClosed);
          resolve();
        }
      }, 100);

      // タイムアウト: 10秒
      setTimeout(() => {
        clearInterval(checkClosed);
        if (this.state !== 'closed') {
          console.warn('Finish timeout, forcing close');
          this.ws?.close();
          this.state = 'closed';
        }
        resolve();
      }, 10000);
    });
  }

  /**
   * 接続を強制終了
   */
  disconnect(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.state = 'disconnected';
    this.sessionId = null;
  }
}

