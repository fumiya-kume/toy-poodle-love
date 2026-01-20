import WebSocket from 'ws';

export type QwenTTSModel =
  | 'qwen3-tts-flash-realtime'
  | 'qwen3-tts-flash-realtime-2025-11-27'
  | 'qwen3-tts-vc-realtime'
  | 'qwen3-tts-vc-realtime-2026-01-15'
  | 'qwen3-tts-vd-realtime'
  | 'qwen3-tts-vd-realtime-2025-12-16';

export type QwenTTSRegion = 'china' | 'international';

export type AudioFormat = 'pcm' | 'wav' | 'mp3' | 'opus';

export interface QwenTTSOptions {
  model?: QwenTTSModel;
  voice?: string;
  format?: AudioFormat;
  sampleRate?: number;
}

interface SessionCreatedEvent {
  type: 'session.created';
  session_id?: string;
}

interface SessionUpdatedEvent {
  type: 'session.updated';
}

interface ResponseAudioDeltaEvent {
  type: 'response.audio.delta';
  delta: string; // base64 encoded audio
}

interface ResponseDoneEvent {
  type: 'response.done';
}

interface ErrorEvent {
  type: 'error';
  error?: {
    message?: string;
    code?: string;
  };
}

type ServerEvent =
  | SessionCreatedEvent
  | SessionUpdatedEvent
  | ResponseAudioDeltaEvent
  | ResponseDoneEvent
  | ErrorEvent
  | { type: string };

// Constants for connection management
const CONNECTION_TIMEOUT_MS = 90000; // 90 seconds (matches other clients)
const MAX_AUDIO_SIZE_BYTES = 50 * 1024 * 1024; // 50MB limit

export class QwenTTSClient {
  private apiKey: string;
  private region: QwenTTSRegion;
  private wsUrl: string;

  constructor(apiKey: string, region: QwenTTSRegion = 'international') {
    this.apiKey = apiKey;
    this.region = region;
    this.wsUrl = region === 'china'
      ? 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime'
      : 'wss://dashscope-intl.aliyuncs.com/api-ws/v1/realtime';
  }

  async synthesize(
    text: string,
    options: QwenTTSOptions = {}
  ): Promise<Buffer> {
    const {
      model = 'qwen3-tts-flash-realtime',
      voice = 'Cherry',
      format = 'pcm',
      sampleRate = 24000,
    } = options;

    return new Promise((resolve, reject) => {
      const audioChunks: Buffer[] = [];
      let totalAudioSize = 0;
      let sessionFinished = false;
      let timeoutId: NodeJS.Timeout | null = null;

      const wsUrlWithModel = `${this.wsUrl}?model=${model}`;

      const ws = new WebSocket(wsUrlWithModel, {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
        },
      });

      // Set up connection timeout
      timeoutId = setTimeout(() => {
        if (!sessionFinished) {
          ws.close();
          reject(new Error(`QwenTTS WebSocket timeout: Connection timed out after ${CONNECTION_TIMEOUT_MS}ms`));
        }
      }, CONNECTION_TIMEOUT_MS);

      const clearTimeoutIfSet = () => {
        if (timeoutId) {
          clearTimeout(timeoutId);
          timeoutId = null;
        }
      };

      const sessionUpdateMessage = {
        type: 'session.update',
        session: {
          mode: 'server_commit',
          voice,
          language_type: 'Auto',
          response_format: format,
          sample_rate: sampleRate,
        },
      };

      const textAppendMessage = {
        type: 'input_text_buffer.append',
        text,
      };

      const textCommitMessage = {
        type: 'input_text_buffer.commit',
      };

      const sessionFinishMessage = {
        type: 'session.finish',
      };

      ws.on('open', () => {
        console.log('QwenTTS WebSocket connected:', {
          model,
          voice,
          format,
        });
      });

      ws.on('message', (data: WebSocket.RawData) => {
        try {
          const message = JSON.parse(data.toString()) as ServerEvent;
          console.log('QwenTTS event:', message.type);

          switch (message.type) {
            case 'session.created':
              console.log('QwenTTS session created');
              ws.send(JSON.stringify(sessionUpdateMessage));
              break;

            case 'session.updated':
              console.log('QwenTTS session updated, sending text');
              ws.send(JSON.stringify(textAppendMessage));
              ws.send(JSON.stringify(textCommitMessage));
              break;

            case 'response.audio.delta': {
              const deltaEvent = message as ResponseAudioDeltaEvent;
              if (deltaEvent.delta) {
                const audioBuffer = Buffer.from(deltaEvent.delta, 'base64');
                totalAudioSize += audioBuffer.length;

                // Check memory limit
                if (totalAudioSize > MAX_AUDIO_SIZE_BYTES) {
                  clearTimeoutIfSet();
                  ws.close();
                  reject(new Error(`QwenTTS error: Audio size exceeded maximum limit of ${MAX_AUDIO_SIZE_BYTES / 1024 / 1024}MB`));
                  return;
                }

                audioChunks.push(audioBuffer);
              }
              break;
            }

            case 'response.done':
              console.log('QwenTTS response done');
              ws.send(JSON.stringify(sessionFinishMessage));
              break;

            case 'session.finished':
              console.log('QwenTTS session finished');
              sessionFinished = true;
              clearTimeoutIfSet();
              ws.close();
              const finalBuffer = Buffer.concat(audioChunks);
              resolve(finalBuffer);
              break;

            case 'error': {
              const errorEvent = message as ErrorEvent;
              const errorMsg = errorEvent.error?.message || 'Unknown error';
              console.error('QwenTTS error:', errorMsg);
              clearTimeoutIfSet();
              ws.close();
              reject(new Error(`QwenTTS error: ${errorMsg}`));
              break;
            }

            default:
              console.log('QwenTTS unknown event:', message.type);
          }
        } catch (err) {
          console.error('Failed to parse QwenTTS message:', err);
          console.error('Raw data:', data.toString());
        }
      });

      ws.on('error', (error) => {
        console.error('QwenTTS WebSocket error:', error);
        clearTimeoutIfSet();
        reject(new Error(`QwenTTS WebSocket error: ${error.message}`));
      });

      ws.on('close', (code, reason) => {
        console.log('QwenTTS WebSocket closed:', code, reason.toString());
        clearTimeoutIfSet();

        // If session didn't finish properly, reject the promise
        if (!sessionFinished) {
          reject(
            new Error(
              `QwenTTS WebSocket closed unexpectedly: ${code} ${reason.toString()}`
            )
          );
        }
      });
    });
  }
}
