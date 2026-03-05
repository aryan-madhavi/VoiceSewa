/**
 * sessionManager.js
 *
 * In-memory store for active call sessions.
 * Each session holds up to 2 users (caller + receiver).
 * Sessions are auto-cleaned after TTL to prevent memory leaks.
 */

const SESSION_TTL = parseInt(process.env.SESSION_TTL_MS ?? '7200000', 10); // 2 hrs default

/**
 * Session shape:
 * {
 *   id: string,
 *   createdAt: number,
 *   cleanupTimer: NodeJS.Timeout,
 *   users: Array<{
 *     ws: WebSocket,
 *     sourceLang: string,
 *     targetLang: string,
 *     voiceLang: string,
 *     pipeline: ReturnType<createTranslationSession>,
 *   }>
 * }
 */
const sessions = new Map();

export function createSession(id) {
  // Auto-expire sessions to prevent memory leaks from abandoned calls
  const cleanupTimer = setTimeout(() => {
    console.log(`[Session] TTL expired — removing session ${id}`);
    destroySession(id);
  }, SESSION_TTL);

  const session = {
    id,
    createdAt: Date.now(),
    cleanupTimer,
    users: [],
  };

  sessions.set(id, session);
  return session;
}

export function getSession(id) {
  return sessions.get(id) ?? null;
}

export function destroySession(id) {
  const session = sessions.get(id);
  if (!session) return;

  clearTimeout(session.cleanupTimer);

  // Stop all active pipelines
  for (const user of session.users) {
    user.pipeline?.stop();
  }

  sessions.delete(id);
  console.log(`[Session] Destroyed session ${id}`);
}

export function removeUserFromSession(session, userEntry) {
  userEntry.pipeline?.stop();
  session.users = session.users.filter((u) => u !== userEntry);

  // Destroy session when empty
  if (session.users.length === 0) {
    destroySession(session.id);
  }
}

export function getSessionCount() {
  return sessions.size;
}