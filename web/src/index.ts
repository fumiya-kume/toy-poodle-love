import * as dotenv from 'dotenv';
import { QwenClient } from './qwen-client';
import { GeminiClient } from './gemini-client';

// Load environment variables
dotenv.config();

async function main() {
  const qwenApiKey = process.env.QWEN_API_KEY;
  const qwenRegion = (process.env.QWEN_REGION as 'china' | 'international') || 'international';
  const geminiApiKey = process.env.GEMINI_API_KEY;

  if (!qwenApiKey) {
    console.error('Error: QWEN_API_KEY is not set in .env file');
    process.exit(1);
  }

  if (!geminiApiKey) {
    console.error('Error: GEMINI_API_KEY is not set in .env file');
    process.exit(1);
  }

  // Initialize clients
  const qwenClient = new QwenClient(qwenApiKey, qwenRegion);
  const geminiClient = new GeminiClient(geminiApiKey);

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
