/**
 * A small Dart lexer that finds string literals and skips comments.
 *
 * It understands what matters for finding user-visible text:
 * `//` and `///` comments, nested block comments, single, double and triple
 * quotes, raw strings (`r'...'`), escapes and `${...}` interpolation
 * (whose inner strings are reported as their own literals).
 */

export interface StringLiteral {
  /** 1-based line of the opening quote (or `r` prefix). */
  line: number;
  /** 1-based column of the opening quote (or `r` prefix). */
  column: number;
  /** The literal's own text, with each `${...}` shown as `${…}`. */
  text: string;
  /** The literal exactly as written in the source. */
  raw: string;
  offset: number;
}

const HEBREW = /[֐-׿יִ-ﭏ]/;

export function containsHebrew(text: string): boolean {
  return HEBREW.test(text);
}

function isIdentChar(c: string | undefined): boolean {
  return c !== undefined && /[A-Za-z0-9_$]/.test(c);
}

export function findStringLiterals(src: string): StringLiteral[] {
  const out: StringLiteral[] = [];
  const len = src.length;
  let i = 0;

  const lineStarts = [0];
  for (let k = 0; k < len; k++) if (src[k] === '\n') lineStarts.push(k + 1);

  function position(offset: number): { line: number; column: number } {
    let lo = 0;
    let hi = lineStarts.length - 1;
    while (lo < hi) {
      const mid = (lo + hi + 1) >> 1;
      if (lineStarts[mid]! <= offset) lo = mid;
      else hi = mid - 1;
    }
    return { line: lo + 1, column: offset - lineStarts[lo]! + 1 };
  }

  function skipBlockComment(): void {
    let depth = 0;
    while (i < len) {
      if (src.startsWith('/*', i)) {
        depth++;
        i += 2;
      } else if (src.startsWith('*/', i)) {
        depth--;
        i += 2;
        if (depth === 0) return;
      } else {
        i++;
      }
    }
  }

  function readString(raw: boolean, start: number): void {
    const quote = src[i]!;
    const triple = src.startsWith(quote.repeat(3), i);
    const delim = triple ? quote.repeat(3) : quote;
    i += delim.length;
    let text = '';
    while (i < len) {
      if (src.startsWith(delim, i)) {
        i += delim.length;
        out.push({ ...position(start), text, raw: src.slice(start, i), offset: start });
        return;
      }
      const c = src[i]!;
      if (!triple && c === '\n') break; // unterminated: stop at the line end
      if (!raw && c === '\\') {
        text += src.slice(i, i + 2);
        i += 2;
        continue;
      }
      if (!raw && c === '$' && src[i + 1] === '{') {
        i += 2;
        skipCode(true);
        text += '${…}';
        continue;
      }
      text += c;
      i++;
    }
    out.push({ ...position(start), text, raw: src.slice(start, i), offset: start });
  }

  /** Lexes code; with `stopAtBrace`, returns after the `}` closing an interpolation. */
  function skipCode(stopAtBrace: boolean): void {
    let depth = 0;
    while (i < len) {
      const c = src[i]!;
      if (c === '/' && src[i + 1] === '/') {
        while (i < len && src[i] !== '\n') i++;
        continue;
      }
      if (c === '/' && src[i + 1] === '*') {
        skipBlockComment();
        continue;
      }
      if (c === "'" || c === '"') {
        readString(false, i);
        continue;
      }
      if (c === 'r' && (src[i + 1] === "'" || src[i + 1] === '"') && !isIdentChar(src[i - 1])) {
        const start = i;
        i++;
        readString(true, start);
        continue;
      }
      if (stopAtBrace) {
        if (c === '{') depth++;
        else if (c === '}') {
          if (depth === 0) {
            i++;
            return;
          }
          depth--;
        }
      }
      i++;
    }
  }

  skipCode(false);
  return out.sort((a, b) => a.offset - b.offset);
}
