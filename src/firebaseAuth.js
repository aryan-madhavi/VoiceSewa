/**
 * firebaseAuth.js
 *
 * Initialises Firebase Admin SDK using Application Default Credentials —
 * no key file needed on Cloud Run, it inherits the attached service account
 * automatically via the GCP metadata server.
 *
 * Exports:
 *   verifyFirebaseToken(idToken) → decoded token payload
 *   requireAuth                  → Express middleware for REST routes
 *   verifyWsToken(token)         → for WebSocket handshake auth
 */

import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

// ── Initialise Firebase Admin ─────────────────────────────────────────────────
// On Cloud Run: no config needed — ADC picks up the service account automatically.
// Locally: set GOOGLE_APPLICATION_CREDENTIALS=./secrets/gcloud-key.json in .env
if (getApps().length === 0) {
  initializeApp();
  console.log('[Firebase] Admin SDK initialised (ADC)');
}

const auth = getAuth();

// ── Core token verifier ───────────────────────────────────────────────────────
/**
 * Verify a Firebase ID token issued by your Firebase project.
 * Works for both email/password and phone number auth methods.
 *
 * @param {string} idToken — Bearer token from Flutter's `user.getIdToken()`
 * @returns {Promise<import('firebase-admin/auth').DecodedIdToken>}
 * @throws if token is invalid, expired, or from wrong project
 */
export async function verifyFirebaseToken(idToken) {
  // checkRevoked: true ensures logged-out users can't reuse old tokens
  const decoded = await auth.verifyIdToken(idToken, /* checkRevoked */ true);
  return decoded;
}

// ── Express REST middleware ───────────────────────────────────────────────────
/**
 * Attach to any Express route to require a valid Firebase ID token.
 * Expects: Authorization: Bearer <firebase-id-token>
 *
 * On success: sets req.user = decoded token payload, calls next()
 * On failure: returns 401
 */
export async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization ?? '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Missing or malformed Authorization header',
      hint: 'Expected: Authorization: Bearer <firebase-id-token>',
    });
  }

  const idToken = authHeader.slice(7); // strip "Bearer "

  try {
    req.user = await verifyFirebaseToken(idToken);
    next();
  } catch (err) {
    console.warn('[Auth] Token verification failed:', err.code, err.message);

    const status = err.code === 'auth/id-token-revoked' ? 401 : 403;
    res.status(status).json({
      error: 'Unauthorized',
      code: err.code ?? 'auth/unknown',
    });
  }
}

// ── WebSocket token verifier ──────────────────────────────────────────────────
/**
 * Verify the token passed as a query param on the WS upgrade request.
 * Returns the decoded token or throws — caller decides how to handle.
 *
 * Flutter sends: ws://host/ws?token=<firebase-id-token>&sessionId=...
 *
 * @param {string} token
 * @returns {Promise<import('firebase-admin/auth').DecodedIdToken>}
 */
export async function verifyWsToken(token) {
  if (!token) throw new Error('No token provided');
  return verifyFirebaseToken(token);
}