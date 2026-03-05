/**
 * sessionManager.js
 *
 * In-memory store for active call sessions.
 * Each session holds up to 2 users (caller + receiver).
 *
 * Three-tier TTL strategy (replaces single 2-hour timer):
 *
 *   WAITING_TTL (90s)  — session created but NO WS connection ever arrived.
 *                        Covers: declined calls, missed FCM, receiver offline.
 *                        Must be > Flutter ringingTimeout (30s) + FCM delivery.
 *
 *   RINGING_TTL (60s)  — exactly 1 user is connected, waiting for the partner.
 *                        Starts when first WS connects; cancelled when second joins.
 *                        Also used after a partner disconnects mid-call.
 *
 *   CALL_TTL (2hr)     — absolute max call duration regardless of activity.
 */

const WAITING_TTL_MS = parseInt(process.env.WAITING_TTL_MS ?? '90000',   10); //  90s
const RINGING_TTL_MS = parseInt(process.env.RINGING_TTL_MS ?? '60000',   10); //  60s
const CALL_TTL_MS    = parseInt(process.env.SESSION_TTL_MS ?? '7200000', 10); //   2h

const sessions = new Map();

export function createSession(id) {
  // Destroyed if no WS connection arrives — covers declined/missed/no-FCM calls
  const waitingTimer = setTimeout(() => {
    const s = sessions.get(id);
    if (s && s.users.length === 0) {
      console.log(`[Session] Waiting TTL — no WS ever connected, destroying ${id}`);
      destroySession(id);
    }
  }, WAITING_TTL_MS);

  // Absolute max duration
  const callTimer = setTimeout(() => {
    console.log(`[Session] Call TTL expired, destroying ${id}`);
    destroySession(id);
  }, CALL_TTL_MS);

  const session = {
    id,
    createdAt:     Date.now(),
    _waitingTimer: waitingTimer,
    _ringingTimer: null,
    _callTimer:    callTimer,
    users:         [],
  };

  sessions.set(id, session);
  console.log(`[Session] Created ${id}`);
  return session;
}

export function getSession(id) {
  return sessions.get(id) ?? null;
}

export function destroySession(id) {
  const session = sessions.get(id);
  if (!session) return;

  clearTimeout(session._waitingTimer);
  clearTimeout(session._ringingTimer);
  clearTimeout(session._callTimer);

  for (const user of session.users) {
    try { user.pipeline?.stop(); } catch (_) {}
  }

  sessions.delete(id);
  console.log(`[Session] Destroyed ${id}`);
}

/**
 * Called when the FIRST WebSocket user connects.
 * Cancels the waiting timer and starts the ringing timer.
 */
export function onFirstUserConnected(session) {
  clearTimeout(session._waitingTimer);
  session._waitingTimer = null;

  clearTimeout(session._ringingTimer);
  session._ringingTimer = setTimeout(() => {
    console.log(`[Session] Ringing TTL — second user never joined, destroying ${session.id}`);
    destroySession(session.id);
  }, RINGING_TTL_MS);
}

/**
 * Called when BOTH users are connected.
 * Cancels the ringing timer.
 */
export function onCallStarted(session) {
  clearTimeout(session._ringingTimer);
  session._ringingTimer = null;
}

/**
 * Called on WS close.
 *   0 users left → destroy immediately
 *   1 user left  → short reconnect window, then destroy
 */
export function removeUserFromSession(session, userEntry) {
  try { userEntry.pipeline?.stop(); } catch (_) {}
  session.users = session.users.filter((u) => u !== userEntry);

  if (session.users.length === 0) {
    destroySession(session.id);
  } else {
    clearTimeout(session._ringingTimer);
    session._ringingTimer = setTimeout(() => {
      console.log(`[Session] Partner-left TTL expired, destroying ${session.id}`);
      destroySession(session.id);
    }, RINGING_TTL_MS);
  }
}

export function getSessionCount() {
  return sessions.size;
}