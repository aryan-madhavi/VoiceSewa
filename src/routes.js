/**
 * routes.js
 *
 * REST endpoints:
 *   GET  /health          — liveness probe (for Railway / Render / Docker)
 *   POST /session         — create a new call session, returns sessionId
 *   GET  /session/:id     — check session status
 *   DELETE /session/:id   — manually end a session
 */

import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import {
  createSession,
  getSession,
  destroySession,
  getSessionCount,
} from './sessionManager.js';
import { requireAuth } from './firebaseAuth.js';

const router = Router();

// ── Health / readiness probe ──────────────────────────────────────────────────
router.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    activeSessions: getSessionCount(),
    timestamp: new Date().toISOString(),
  });
});

// ── Create session ────────────────────────────────────────────────────────────
// Requires a valid Firebase ID token — only authenticated app users can start calls.
// Flutter: pass `Authorization: Bearer ${await user.getIdToken()}` header.
router.post('/session', requireAuth, (req, res) => {
  const sessionId = uuidv4();
  createSession(sessionId);

  console.log(`[REST] Created session=${sessionId} by uid=${req.user.uid}`);

  res.status(201).json({
    sessionId,
    wsUrl: `/ws?sessionId=${sessionId}`,
    createdAt: new Date().toISOString(),
  });
});

// ── Session status ────────────────────────────────────────────────────────────
router.get('/session/:id', (req, res) => {
  const session = getSession(req.params.id);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  res.json({
    sessionId: session.id,
    connectedUsers: session.users.length,
    createdAt: new Date(session.createdAt).toISOString(),
    isFull: session.users.length >= 2,
  });
});

// ── End session manually ──────────────────────────────────────────────────────
router.delete('/session/:id', requireAuth, (req, res) => {
  const session = getSession(req.params.id);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  destroySession(req.params.id);
  console.log(`[REST] Manually destroyed session=${req.params.id}`);

  res.json({ success: true });
});

export default router;