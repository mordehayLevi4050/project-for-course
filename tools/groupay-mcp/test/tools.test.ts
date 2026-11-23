import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { InMemoryTransport } from '@modelcontextprotocol/sdk/inMemory.js';
import { containsHebrew, findStringLiterals } from '../src/dartStrings.ts';
import { findMessages, loadCatalog, parseMessageKeys, parseSpecMessages } from '../src/messages.ts';
import { createServer, defaultRoot } from '../src/server.ts';

describe('findStringLiterals', () => {
  it('skips line, doc and nested block comments', () => {
    const src = `// 'שלום'\n/// "שלום"\n/* a /* 'שלום' */ b */\nfinal x = 'ok';`;
    assert.deepEqual(findStringLiterals(src).map((l) => l.text), ['ok']);
  });

  it('reports line and column of each literal', () => {
    const [lit] = findStringLiterals(`void f() {\n  Text('שלום');\n}`);
    assert.equal(lit?.line, 2);
    assert.equal(lit?.column, 8);
    assert.equal(lit?.raw, `'שלום'`);
  });

  it('handles escapes, raw and triple-quoted strings', () => {
    const src = `a('it\\'s'); b(r'c:\\x'); c('''multi\nline'''); d("q\\"q");`;
    assert.deepEqual(findStringLiterals(src).map((l) => l.text), [
      `it\\'s`,
      `c:\\x`,
      'multi\nline',
      'q\\"q',
    ]);
  });

  it('reports strings inside interpolation as their own literals', () => {
    const lits = findStringLiterals(`'a \${f('שלום', {1: 2})} b'`);
    assert.deepEqual(lits.map((l) => l.text), ['a ${…} b', 'שלום']);
  });

  it('does not treat an identifier ending in r as a raw prefix', () => {
    assert.deepEqual(findStringLiterals(`bar'x'`).map((l) => l.raw), [`'x'`]);
  });
});

describe('containsHebrew', () => {
  it('detects Hebrew letters only', () => {
    assert.equal(containsHebrew('נדרש שם'), true);
    assert.equal(containsHebrew('GrouPay ₪ ✕'), false);
  });
});

describe('messages', () => {
  it('parses entries, doc comments, fixed flags and placeholders', () => {
    const src = `enum MessageKey {
  /// fixed: "Name required"
  nameRequired('נדרש שם'),

  /// {name} must be isolated.
  removeMemberTitle(
    'להסיר את {name}?',
  ),
  quote("it's"),
  last('x');

  const MessageKey(this.text);
  other('not an entry'),
}`;
    const keys = parseMessageKeys(src);
    assert.deepEqual(keys.map((k) => k.key), ['nameRequired', 'removeMemberTitle', 'quote', 'last']);
    assert.equal(keys[0]?.fixed, true);
    assert.equal(keys[0]?.english, 'Name required');
    assert.deepEqual(keys[1]?.placeholders, ['name']);
    assert.equal(keys[2]?.hebrew, "it's");
  });

  it('parses the spec table rows', () => {
    const rows = parseSpecMessages(`| English | Hebrew |\n|---|---|\n| "Name required" | "נדרש שם" |`);
    assert.deepEqual(rows, [{ english: 'Name required', hebrew: 'נדרש שם' }]);
  });

  it('finds the real nameRequired key and matches the spec', () => {
    const [m] = findMessages(loadCatalog(defaultRoot()), 'nameRequired');
    assert.equal(m?.hebrew, 'נדרש שם');
    assert.equal(m?.usage, 'MessageKey.nameRequired.text');
    assert.equal(m?.matchesSpec, true);
  });

  it('finds a fixed key by the spec English when its doc has no quoted English', () => {
    const catalog = loadCatalog(defaultRoot());
    assert.deepEqual(
      findMessages(catalog, 'Make this the active group').map((m) => m.key),
      ['activeSheetTitle'],
    );
    assert.deepEqual(
      findMessages(catalog, 'will no longer be').map((m) => m.key),
      ['activeSheetWarning'],
    );
  });

  it('every fixed message linked to the spec matches it exactly', () => {
    const catalog = loadCatalog(defaultRoot());
    const keys = catalog.keys.filter((k) => k.fixed).map((k) => k.key);
    const mismatches = keys
      .flatMap((k) => findMessages(catalog, k))
      .filter((m) => m.matchesSpec === false)
      .map((m) => m.key);
    // transferLine is a template on purpose: the "מ"/"ל" prefixes come in
    // through isolateName() and the ₪ amount is its own widget.
    assert.deepEqual(mismatches, ['transferLine']);
  });
});

describe('MCP server', () => {
  async function connect() {
    const [clientSide, serverSide] = InMemoryTransport.createLinkedPair();
    await createServer().connect(serverSide);
    const client = new Client({ name: 'test', version: '0.0.0' });
    await client.connect(clientSide);
    return client;
  }

  it('lists both tools', async () => {
    const client = await connect();
    const { tools } = await client.listTools();
    assert.deepEqual(tools.map((t) => t.name).sort(), ['check_hebrew_literals', 'get_message']);
  });

  it('get_message searches by English text', async () => {
    const client = await connect();
    const res = await client.callTool({ name: 'get_message', arguments: { query: 'settled up' } });
    const body = JSON.parse((res.content as { text: string }[])[0]!.text);
    assert.equal(body.matches[0].key, 'settledUp');
  });

  it('check_hebrew_literals finds a literal and skips lib/core/i18n', async () => {
    const client = await connect();
    const res = await client.callTool({ name: 'check_hebrew_literals', arguments: {} });
    const body = JSON.parse((res.content as { text: string }[])[0]!.text);
    assert.equal(body.scope, 'lib');
    assert.deepEqual(body.skipped, ['lib/core/i18n']);
    assert.ok(body.filesScanned > 0);
  });

  it('check_hebrew_literals refuses a path outside the project', async () => {
    const client = await connect();
    const res = await client.callTool({ name: 'check_hebrew_literals', arguments: { path: '../..' } });
    assert.equal(res.isError, true);
  });
});
