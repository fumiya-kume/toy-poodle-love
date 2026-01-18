import { initializeDotenv, getEnv, validateRequiredKeys } from './config';
import { QwenClient } from './qwen-client';
import { GeminiClient } from './gemini-client';

// Load environment variables
initializeDotenv();

async function main() {
  try {
    validateRequiredKeys(['qwen', 'gemini']);
  } catch (error) {
    console.error('Error:', (error as Error).message);
    process.exit(1);
  }

  const env = getEnv();

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
