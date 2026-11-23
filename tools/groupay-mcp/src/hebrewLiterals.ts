import { readdirSync, readFileSync, statSync } from 'node:fs';
import { isAbsolute, join, relative, resolve, sep } from 'node:path';
import { containsHebrew, findStringLiterals } from './dartStrings.ts';
import type { MessageEntry } from './messages.ts';

/** Where Hebrew text is allowed to live (CLAUDE.md › Strings). */
export const ALLOWED_DIRS = ['lib/core/i18n'];

export interface HebrewLiteral {
  file: string;
  line: number;
  column: number;
  literal: string;
  /** The MessageKey that already shows this exact text, if any. */
  suggestion: string | null;
}

export interface ScanResult {
  scope: string;
  filesScanned: number;
  skipped: string[];
  findings: HebrewLiteral[];
}

function toPosix(p: string): string {
  return p.split(sep).join('/');
}

/** Resolves `scope` inside `root`, refusing paths that leave the project. */
export function resolveScope(root: string, scope: string): string {
  const abs = resolve(root, scope);
  const rel = relative(root, abs);
  if (rel === '..' || rel.startsWith('..' + sep) || isAbsolute(rel)) {
    throw new Error(`Scope "${scope}" is outside the project.`);
  }
  return abs;
}

export function scanHebrewLiterals(
  root: string,
  scope: string,
  options: { includeAllowed: boolean; keys: MessageEntry[] },
): ScanResult {
  const absScope = resolveScope(root, scope);
  const byText = new Map(options.keys.map((k) => [k.hebrew, k.key]));
  const skipped = new Set<string>();
  const findings: HebrewLiteral[] = [];
  let filesScanned = 0;

  const files = statSync(absScope).isFile()
    ? [toPosix(relative(root, absScope))]
    : readdirSync(absScope, { recursive: true, withFileTypes: true })
        .filter((d) => d.isFile() && d.name.endsWith('.dart'))
        .map((d) => toPosix(relative(root, join(d.parentPath, d.name))))
        .sort();

  for (const file of files) {
    if (file.endsWith('.g.dart')) continue; // generated code
    const allowed = ALLOWED_DIRS.find((dir) => file.startsWith(`${dir}/`));
    if (allowed && !options.includeAllowed) {
      skipped.add(allowed);
      continue;
    }
    filesScanned++;
    const source = readFileSync(join(root, file), 'utf8');
    for (const lit of findStringLiterals(source)) {
      if (!containsHebrew(lit.text)) continue;
      const key = byText.get(lit.text);
      findings.push({
        file,
        line: lit.line,
        column: lit.column,
        literal: lit.raw,
        suggestion: key ? `MessageKey.${key}` : null,
      });
    }
  }

  return { scope: toPosix(relative(root, absScope)) || '.', filesScanned, skipped: [...skipped], findings };
}
