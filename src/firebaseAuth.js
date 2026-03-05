/**
 * firebaseAuth.js
 *
 * Initialises Firebase Admin SDK using Application Default Credentials —
 * no key file needed on Cloud Run; it inherits the attached service account
 * automatically via the GCP metadata server.
 *
 * Exports:
 *   verifyFirebaseToken(idToken, checkRevoked?)  → decoded token payload
 *   requireAuth                                  → Express middleware (REST routes)
 *   verifyWsToken(token)                         → WebSocket handshake auth
 */

import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

if (getApps().length === 0) {
  initializeApp();
  console.log('[Firebase] Admin SDK initialised (ADC)');
}

const auth = getAuth();

/**
 * @param {string}  idToken
 * @param {boolean} checkRevoked
 *   true  — makes a network call to Firebase to verify the token isn't revoked.
 *            Use for REST mutations (POST /session) where you want to be sure a
 *            logged-out user can't reuse an old token.
 *   false — JWT-only verification (signature + expiry). No network call.
 *           Saves 200-800ms per WS connection. Safe because:
 *           (a) tokens expire after 1 hour anyway, and
 *           (b) WS connections are short-lived and don't mutate critical state.
 */
export async function verifyFirebaseToken(idToken, checkRevoked = false) {
  return auth.verifyIdToken(idToken, checkRevoked);
}

// ── Express REST middleware ───────────────────────────────────────────────────
// Uses checkRevoked=true for REST routes since they create sessions (state mutation).
export async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization ?? '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Missing or malformed Authorization header',
      hint:  'Expected: Authorization: Bearer <firebase-id-token>',
    });
  }

  const idToken = authHeader.slice(7);

  try {
    req.user = await verifyFirebaseToken(idToken, /* checkRevoked */ true);
    next();
  } catch (err) {
    console.warn('[Auth] REST token verification failed:', err.code, err.message);
    const status = err.code === 'auth/id-token-revoked' ? 401 : 403;
    res.status(status).json({ error: 'Unauthorized', code: err.code ?? 'auth/unknown' });
  }
}

// ── WebSocket token verifier ──────────────────────────────────────────────────
// checkRevoked=false: no extra network round-trip on every WS connection.
export async function verifyWsToken(token) {
  if (!token) throw new Error('No token provided');
  return verifyFirebaseToken(token, /* checkRevoked */ false);
}