import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export const MESSAGE_KEY_FILE = 'lib/core/i18n/message_key.dart';
export const UI_MESSAGES_FILE = '_bmad-output/specs/spec-groupay/ui-messages.md';

export interface MessageEntry {
  /** The MessageKey enum value, e.g. `nameRequired`. */
  key: string;
  /** The Hebrew text the app shows. */
  hebrew: string;
  /** The doc comment above the entry, without the `///`. */
  doc: string;
  /** True when the doc comment marks it "fixed" (spec text, never reworded). */
  fixed: boolean;
  /** The English reference from `fixed: "..."`, when the comment has one. */
  english: string | null;
  /** `{name}` style placeholders, in order. */
  placeholders: string[];
}

export interface SpecMessage {
  english: string;
  hebrew: string;
}

function unescapeDart(s: string): string {
  return s.replace(/\\(.)/g, '$1');
}

export function parseMessageKeys(source: string): MessageEntry[] {
  const start = source.indexOf('enum MessageKey {');
  if (start < 0) throw new Error(`No "enum MessageKey {" in ${MESSAGE_KEY_FILE}`);
  const endMarker = source.indexOf('const MessageKey(', start);
  const body = source.slice(start, endMarker < 0 ? undefined : endMarker);

  const entry =
    /((?:[ \t]*\/\/\/.*\r?\n)*)[ \t]*(\w+)\(\s*(?:'((?:\\.|[^'\\])*)'|"((?:\\.|[^"\\])*)")\s*,?\s*\)/g;
  const result: MessageEntry[] = [];
  for (const m of body.matchAll(entry)) {
    const doc = (m[1] ?? '')
      .split(/\r?\n/)
      .map((l) => l.replace(/^\s*\/\/\/\s?/, ''))
      .filter((l) => l.length > 0)
      .join(' ');
    const hebrew = unescapeDart(m[3] ?? m[4] ?? '');
    result.push({
      key: m[2]!,
      hebrew,
      doc,
      fixed: /\bfixed:/.test(doc),
      english: doc.match(/fixed:\s*"([^"]+)"/)?.[1] ?? null,
      placeholders: [...hebrew.matchAll(/\{(\w+)\}/g)].map((p) => p[1]!),
    });
  }
  return result;
}

export function parseSpecMessages(markdown: string): SpecMessage[] {
  const rows: SpecMessage[] = [];
  for (const line of markdown.split(/\r?\n/)) {
    const m = line.match(/^\|\s*"(.+)"\s*\|\s*"(.+)"\s*\|\s*$/);
    if (m) rows.push({ english: m[1]!, hebrew: m[2]! });
  }
  return rows;
}

export interface MessageCatalog {
  keys: MessageEntry[];
  spec: SpecMessage[];
}

/** Reads both files fresh on every call, so edits show up without a restart. */
export function loadCatalog(root: string): MessageCatalog {
  return {
    keys: parseMessageKeys(readFileSync(join(root, MESSAGE_KEY_FILE), 'utf8')),
    spec: parseSpecMessages(readFileSync(join(root, UI_MESSAGES_FILE), 'utf8')),
  };
}

export interface MessageMatch {
  key: string | null;
  hebrew: string;
  english: string | null;
  fixed: boolean;
  placeholders: string[];
  /** How to use it in Dart, or null when the message is only in the spec. */
  usage: string | null;
  doc: string;
  /** The spec's Hebrew for a fixed message, when one is linked. */
  specHebrew: string | null;
  /** true / false when linked to the spec; null when there is nothing to compare. */
  matchesSpec: boolean | null;
}

function specRowFor(entry: MessageEntry, spec: SpecMessage[]): SpecMessage | undefined {
  return (
    spec.find((r) => r.hebrew === entry.hebrew) ??
    (entry.english ? spec.find((r) => r.english === entry.english) : undefined)
  );
}

function toMatch(entry: MessageEntry, spec: SpecMessage[]): MessageMatch {
  const row = entry.fixed ? specRowFor(entry, spec) : undefined;
  const args = entry.placeholders.map((p) => `'${p}': …`).join(', ');
  return {
    key: entry.key,
    hebrew: entry.hebrew,
    english: entry.english ?? row?.english ?? null,
    fixed: entry.fixed,
    placeholders: entry.placeholders,
    usage: entry.placeholders.length
      ? `MessageKey.${entry.key}.fill({${args}})`
      : `MessageKey.${entry.key}.text`,
    doc: entry.doc,
    specHebrew: row?.hebrew ?? null,
    matchesSpec: row ? row.hebrew === entry.hebrew : null,
  };
}

/**
 * Finds messages by exact key, or by a case-insensitive substring of the key,
 * the English reference, the Hebrew text or the doc comment. Spec messages
 * that no MessageKey shows yet are returned too, with `key: null`.
 */
export function findMessages(catalog: MessageCatalog, query: string, limit = 20): MessageMatch[] {
  const q = query.trim();
  const exact = catalog.keys.find((e) => e.key === q);
  if (exact) return [toMatch(exact, catalog.spec)];

  const needle = q.toLowerCase();
  const has = (s: string | null) => s !== null && s.toLowerCase().includes(needle);

  // Filter on the match, not the raw entry: a fixed key whose doc comment has
  // no quoted English gets its English from the linked spec row in toMatch.
  const matches = catalog.keys
    .map((e) => toMatch(e, catalog.spec))
    .filter((m) => has(m.key) || has(m.english) || has(m.hebrew) || has(m.doc));

  const shownInApp = new Set(catalog.keys.map((e) => e.hebrew));
  const linkedEnglish = new Set(catalog.keys.map((e) => e.english).filter(Boolean));
  for (const row of catalog.spec) {
    if (shownInApp.has(row.hebrew) || linkedEnglish.has(row.english)) continue;
    if (has(row.english) || has(row.hebrew)) {
      matches.push({
        key: null,
        hebrew: row.hebrew,
        english: row.english,
        fixed: true,
        placeholders: [],
        usage: null,
        doc: `Only in ${UI_MESSAGES_FILE}; no MessageKey shows this exact text.`,
        specHebrew: row.hebrew,
        matchesSpec: null,
      });
    }
  }
  return matches.slice(0, limit);
}
