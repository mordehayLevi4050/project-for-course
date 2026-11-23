import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { createServer, defaultRoot } from './server.ts';

// stdout carries the MCP protocol, so logs go to stderr only.
const root = defaultRoot();
await createServer(root).connect(new StdioServerTransport());
console.error(`groupay-spec MCP server running (project root: ${root})`);
