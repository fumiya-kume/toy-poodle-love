import { initializeDotenv, getEnv, validateRequiredKeys } from './config';
import { initARMSTracing } from './telemetry';
import { QwenClient } from './qwen-client';
import { GeminiClient } from './gemini-client';

// Load environment variables
initializeDotenv();

// Initialize ARMS LLMOps tracing (must be called before any LLM API calls)
const env = getEnv();
initARMSTracing({
  endpoint: env.armsEndpoint,
  authToken: env.armsAuthToken,
  serviceName: env.otelServiceName,
  disabled: env.armsTracingDisabled,
});

async function main() {
  try {
    validateRequiredKeys(['qwen', 'gemini']);
  } catch (error) {
    console.error('Error:', (error as Error).message);
    process.exit(1);
  }

  // Initialize clients
  const qwenClient = new QwenClient(env.qwenApiKey!, env.qwenRegion);
  const geminiClient = new GeminiClient(env.geminiApiKey!);

  const testMessage = 'Hello! Please introduce yourself briefly.';

  console.log('=== Testing Qwen API ===');
  console.log(`Question: ${testMessage}\n`);
  try {
    const qwenResponse = await qwenClient.chat(testMessage);
    console.log('Qwen Response:', qwenResponse);
  } catch (error) {
    console.error('Qwen Error:', error);
  }

  console.log('\n=== Testing Gemini API ===');
  console.log(`Question: ${testMessage}\n`);
  try {
    const geminiResponse = await geminiClient.chat(testMessage);
    console.log('Gemini Response:', geminiResponse);
  } catch (error) {
    console.error('Gemini Error:', error);
  }
}

main().catch(console.error);
