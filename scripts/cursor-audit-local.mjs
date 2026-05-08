#!/usr/bin/env node
/**
 * Локальний агент проти робочої копії LostNumber через @cursor/sdk.
 * Потребує CURSOR_API_KEY (див. https://cursor.com/dashboard/cloud-agents).
 *
 * Режими:
 * - За замовчуванням: Agent.prompt — один запит, відповідь цілком у кінці (простіше для CI).
 * - `--stream` або CURSOR_AUDIT_STREAM=1: Agent.create + run.stream — текст відповіді в реальному часу,
 *   плюс agentId/runId у stderr для розслідування в Dashboard (це і є «навіщо SDK» поруч із чатом).
 *
 * Навіщо: узгоджений промпт із доступом до всього дерева файлів без копіпасту в чат —
 * зручно перед релізом або коли ESLint не ловить логічні/UX проблеми.
 */

import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const cwd = resolve(__dirname, '..');

let Agent;
let CursorAgentError;
try {
  ({ Agent, CursorAgentError } = await import('@cursor/sdk'));
} catch (e) {
  const msg = e instanceof Error ? e.message : String(e);
  console.error('Не вдалося завантажити @cursor/sdk. Виконайте npm install.', `\n(${msg})`);
  if (msg.includes('@cursor/sdk')) {
    console.error(
      'Підказка: якщо node_modules підозрілий (ENOENT/TAR помилки), видаліть папку node_modules і знову npm install.',
    );
  }
  process.exit(127);
}

const defaultPrompt =
  'You audit the LostNumber browser game repo (vanilla JS under js/). Focus on reliability and UX continuity.\n' +
  '- Read primarily: js/system/errorHandler.js, js/system/errorHandlerFallback.js, js/system/freezeSystem.js, js/system/i18n.js, js/system/storage.js, js/ui/.\n' +
  '- Output exactly: (1) three highest-impact concrete improvements with file paths and why; (2) one i18n or user-facing consistency note.\n' +
  '- Advisory only: do not propose editing files in this run.';

const prompt = process.env.CURSOR_AUDIT_PROMPT?.trim() || defaultPrompt;
const apiKey = process.env.CURSOR_API_KEY?.trim();
const useStream =
  process.argv.includes('--stream') ||
  String(process.env.CURSOR_AUDIT_STREAM ?? '').trim() === '1';

const agentOptions = {
  apiKey,
  model: { id: 'composer-2' },
  local: { cwd, settingSources: [] },
};

if (!apiKey) {
  console.error('Встановіть CURSOR_API_KEY (PowerShell: $env:CURSOR_API_KEY = "cursor_..." )');
  process.exit(2);
}

/**
 * @returns {Promise<{ status: string, result?: unknown }>}
 */
async function runAuditStreaming() {
  const agent = Agent.create(agentOptions);
  try {
    const run = await agent.send(prompt);
    console.error('[cursor-sdk]', 'agentId=', agent.agentId, 'runId=', run.id);

    let streamedText = false;
    if (typeof run.supports === 'function' && run.supports('stream')) {
      for await (const event of run.stream()) {
        if (event.type === 'assistant' && event.message?.content) {
          for (const block of event.message.content) {
            if (block.type === 'text' && block.text) {
              process.stdout.write(block.text);
              streamedText = true;
            }
          }
        }
      }
    } else if (typeof run.unsupportedReason === 'function') {
      console.error('[cursor-sdk] stream:', run.unsupportedReason('stream'));
    }

    const result = await run.wait();
    if (!streamedText && result.result != null && typeof result.result === 'string') {
      console.log('\n--- result ---\n');
      console.log(result.result);
    }
    console.log('[status]', result.status);
    return result;
  } finally {
    const dispose = agent[Symbol.asyncDispose];
    if (typeof dispose === 'function') {
      await dispose.call(agent);
    }
  }
}

try {
  const result = useStream ? await runAuditStreaming() : await Agent.prompt(prompt, agentOptions);

  if (!useStream) {
    console.log('[status]', result.status);
    if (result.result != null && typeof result.result === 'string') {
      console.log('\n--- result ---\n');
      console.log(result.result);
    }
  }

  if (result.status === 'error') {
    process.exitCode = 3;
  }
} catch (err) {
  if (CursorAgentError && err instanceof CursorAgentError) {
    console.error('[CursorAgentError]', err.message, 'retryable=', err.isRetryable);
    process.exit(1);
  }
  throw err;
}
