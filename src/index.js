/**
 * index.js — Entry point
 *
 * Cloud Run notes:
 *  - No GOOGLE_APPLICATION_CREDENTIALS needed — ADC auto-authenticates via
 *    the attached service account on the Cloud Run instance.
 *  - PORT is injected automatically by Cloud Run (default 8080).
 *  - WebSockets work on Cloud Run with session affinity + timeout set to 3600s.
 */

import http from 'node:http';
import express from 'express';
import routes from './routes.js';
import { attachWebSocketServer } from './wsHandler.js';

// ── Load .env locally only ────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'production') {
  try {
    const { readFileSync } = await import('node:fs');
    const env = readFileSync('.env', 'utf8');
    for (const line of env.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx === -1) continue;
      const key = trimmed.slice(0, eqIdx).trim();
      const val = trimmed.slice(eqIdx + 1).trim();
      if (!process.env[key]) process.env[key] = val;
    }
    console.log('[Env] Loaded .env file');
  } catch { /* no .env — fine in CI/prod */ }
}

// ── Validate env ──────────────────────────────────────────────────────────────
// Cloud Run: only GOOGLE_CLOUD_PROJECT needed — ADC handles auth automatically.
// Local dev: also set GOOGLE_APPLICATION_CREDENTIALS in .env.
if (!process.env.GOOGLE_CLOUD_PROJECT) {
  console.error('[Startup] Missing required env var: GOOGLE_CLOUD_PROJECT');
  process.exit(1);
}

// ── Express ───────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json());

app.use((_req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (_req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

app.use('/', routes);

// ── Server ────────────────────────────────────────────────────────────────────
// Cloud Run sets PORT=8080 automatically
const PORT = parseInt(process.env.PORT ?? '8080', 10);
const server = http.createServer(app);

attachWebSocketServer(server);

server.listen(PORT, '0.0.0.0', () => {
  const isCloudRun = !!process.env.K_SERVICE;
  console.log('');
  console.log('┌──────────────────────────────────────────────────┐');
  console.log('│    VoiceSewa  ·  Auto-Translate Call Server      │');
  console.log('├──────────────────────────────────────────────────┤');
  console.log(`│  Port     →  ${PORT}                                │`);
  console.log(`│  Runtime  →  ${isCloudRun ? 'Cloud Run' : 'local dev'}                           │`);
  console.log(`│  Project  →  ${process.env.GOOGLE_CLOUD_PROJECT}                           │`);
  console.log('└──────────────────────────────────────────────────┘');
  console.log('');
});

// ── Graceful shutdown (Cloud Run sends SIGTERM on scale-down) ─────────────────
const shutdown = (signal) => {
  console.log(`\n[Shutdown] ${signal} — draining connections...`);
  server.close(() => { console.log('[Shutdown] Done.'); process.exit(0); });
  // Force exit after 9s (Cloud Run waits max 10s after SIGTERM)
  setTimeout(() => process.exit(1), 9000);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));