import 'dotenv/config';
import { readFileSync } from 'fs';
import { createServer } from 'http';
import express from 'express';
import { WebSocketServer } from 'ws';
import admin from 'firebase-admin';

import routes from './routes.js';
import { handleUpgrade } from './wsHandler.js';
import { cleanupExpiredSessions } from './sessionManager.js';

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
