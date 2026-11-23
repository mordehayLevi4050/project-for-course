import { resolve } from 'node:path';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { scanHebrewLiterals } from './hebrewLiterals.ts';
import { findMessages, loadCatalog } from './messages.ts';

/** The GrouPay repo root: GROUPAY_ROOT, or three levels up from src/. */
export function defaultRoot(): string {
  return process.env.GROUPAY_ROOT ?? resolve(import.meta.dirname, '..', '..', '..');
}

function json(value: unknown) {
  return { content: [{ type: 'text' as const, text: JSON.stringify(value, null, 2) }] };
}

function failure(error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  return { content: [{ type: 'text' as const, text: message }], isError: true };
}

export function createServer(root: string = defaultRoot()): McpServer {
  const server = new McpServer({ name: 'groupay-spec', version: '0.1.0' });

  server.registerTool(
    'get_message',
    {
      title: 'Get a GrouPay UI message',
      description:
        'Looks up user-visible text in the GrouPay MessageKey table (lib/core/i18n/message_key.dart) ' +
        'and the fixed spec messages (ui-messages.md). Pass an exact key such as "nameRequired", ' +
        'or any part of the key, the English reference or the Hebrew text. Returns the Hebrew text, ' +
        'the Dart usage (MessageKey.x.text or .fill), placeholders, and for fixed messages whether ' +
        'the code still matches the spec exactly. Use it before writing any user-visible string.',
      inputSchema: {
        query: z.string().min(1).describe('A MessageKey name, or text to search for (English or Hebrew).'),
      },
      annotations: { readOnlyHint: true },
    },
    async ({ query }) => {
      try {
        const matches = findMessages(loadCatalog(root), query);
        return json({ query, count: matches.length, matches });
      } catch (error) {
        return failure(error);
      }
    },
  );

  server.registerTool(
    'check_hebrew_literals',
    {
      title: 'Find Hebrew literals in Dart code',
      description:
        'Scans Dart files for string literals that contain Hebrew. In GrouPay all user-visible text ' +
        'must come from MessageKey in lib/core/i18n, so every finding outside it breaks the rule. ' +
        'Comments are ignored; generated *.g.dart files and lib/core/i18n are skipped. ' +
        'When the literal equals an existing message, the finding suggests its MessageKey.',
      inputSchema: {
        path: z
          .string()
          .default('lib')
          .describe('File or folder to scan, relative to the project root. Default: lib'),
        includeAllowed: z
          .boolean()
          .default(false)
          .describe('Also scan lib/core/i18n, where Hebrew is allowed. Default: false'),
      },
      annotations: { readOnlyHint: true },
    },
    async ({ path, includeAllowed }) => {
      try {
        const { keys } = loadCatalog(root);
        const result = scanHebrewLiterals(root, path, { includeAllowed, keys });
        return json({ ok: result.findings.length === 0, ...result });
      } catch (error) {
        return failure(error);
      }
    },
  );

  return server;
}
