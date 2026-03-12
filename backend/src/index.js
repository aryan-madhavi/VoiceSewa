import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { createServer } from 'http';
import express from 'express';
import { WebSocketServer } from 'ws';
import admin from 'firebase-admin';

import routes from './routes.js';
import { handleUpgrade } from './wsHandler.js';
import { cleanupExpiredSessions } from './sessionManager.js';

// ── Credentials bootstrap ──────────────────────────────────────────────────────
// Railway (and most PaaS hosts) cannot mount secret files — credentials must be
// passed as environment variables instead.
//
// Two modes are supported:
//
//   1. GOOGLE_SERVICE_ACCOUNT_JSON  (Railway / any env-var-only host)
//      Set this to the full contents of your service account JSON. The file is
//      written to /tmp at startup so the three GCP client libraries
//      (Speech, Translate, TTS) can find it via GOOGLE_APPLICATION_CREDENTIALS
//      without any changes to their initialisation code.
//
//   2. GOOGLE_APPLICATION_CREDENTIALS  (Cloud Run / local dev)
//      Set this to the path of the service account JSON file as normal.
//      GOOGLE_SERVICE_ACCOUNT_JSON is not needed.
//
if (process.env.GOOGLE_SERVICE_ACCOUNT_JSON) {
  const tmpPath = '/tmp/sa-key.json';
  writeFileSync(tmpPath, process.env.GOOGLE_SERVICE_ACCOUNT_JSON, { mode: 0o600 });
  process.env.GOOGLE_APPLICATION_CREDENTIALS = tmpPath;
}

// ── Firebase Admin ─────────────────────────────────────────────────────────────
const serviceAccount = JSON.parse(
  readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'),
);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// ── Express ────────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json());
app.use('/', routes);

// ── HTTP + WebSocket server ────────────────────────────────────────────────────
const server = createServer(app);
const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (req, socket, head) => {
  if (req.url?.startsWith('/ws')) {
    handleUpgrade(wss, req, socket, head);
  } else {
    socket.destroy();
  }
});

// ── Housekeeping ───────────────────────────────────────────────────────────────
setInterval(cleanupExpiredSessions, 60_000);

// ── Start ──────────────────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT ?? '8080', 10);
server.listen(PORT, () => {
  console.log(`[server] Listening on port ${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('[server] SIGTERM — shutting down');
  server.close(() => process.exit(0));
});
