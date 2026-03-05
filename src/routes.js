/**
 * routes.js
 *
 * REST endpoints:
 *   GET    /health        -- liveness probe (publicly accessible)
 *   POST   /session       -- create a new call session, returns sessionId
 *   GET    /session/:id   -- check session status
 *   DELETE /session/:id   -- manually end a session
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

// -- Auth middleware: protects all routes EXCEPT /health --
// Cloud Run is set to --allow-unauthenticated so the load balancer passes all
// traffic through. Firebase auth is enforced here at the app layer instead,
// keeping /health publicly reachable for uptime monitoring while protecting
// /session and every other endpoint.
router.use((req, res, next) => {
  if (req.path === '/health') return next();
  return requireAuth(req, res, next);
});

// -- Health / readiness probe (public) --
router.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    activeSessions: getSessionCount(),
    timestamp: new Date().toISOString(),
  });
});

// -- Create session --
// requireAuth is already applied above via middleware, no need to add it here.
router.post('/session', (req, res) => {
  const sessionId = uuidv4();
  createSession(sessionId);

  console.log(`[REST] Created session=${sessionId} by uid=${req.user.uid}`);

  res.status(201).json({
    sessionId,
    wsUrl: `/ws?sessionId=${sessionId}`,
    createdAt: new Date().toISOString(),
  });
});

// -- Session status --
router.get('/session/:id', (req, res) => {
  const session = getSession(req.params.id);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  res.json({
    sessionId:      session.id,
    connectedUsers: session.users.length,
    createdAt:      new Date(session.createdAt).toISOString(),
    isFull:         session.users.length >= 2,
  });
});

// -- End session manually --
router.delete('/session/:id', (req, res) => {
  const session = getSession(req.params.id);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  destroySession(req.params.id);
  console.log(`[REST] Manually destroyed session=${req.params.id}`);

  res.json({ success: true });
});

export default router;