// Session shape:
// {
//   id: string,
//   callerUid: string,
//   receiverUid: string,
//   status: 'waiting' | 'ringing' | 'active' | 'ended',
//   createdAt: number,
//   expiresAt: number,
//   slots: {
//     [uid]: { ws: WebSocket, lang: string, pipeline: TranslationPipeline | null }
//   }
// }

const sessions = new Map();

const TTL = {
  waiting: parseInt(process.env.WAITING_TTL_MS ?? '90000'),
  ringing: parseInt(process.env.RINGING_TTL_MS ?? '60000'),
  active: parseInt(process.env.ACTIVE_TTL_MS ?? '7200000'),
};

export function createSession({ callerUid, receiverUid }) {
  const id = crypto.randomUUID();
  const now = Date.now();
  sessions.set(id, {
    id,
    callerUid,
    receiverUid,
    status: 'waiting',
    createdAt: now,
    expiresAt: now + TTL.waiting,
    slots: {},
  });
  console.log(`[sessions] Created session ${id}: ${callerUid} → ${receiverUid}`);
  return id;
}

export function getSession(id) {
  return sessions.get(id) ?? null;
}

export function deleteSession(id) {
  const session = sessions.get(id);
  if (!session) return;
  for (const slot of Object.values(session.slots)) {
    slot.pipeline?.destroy();
  }
  sessions.delete(id);
  console.log(`[sessions] Deleted session ${id}`);
}

/**
 * Add a user WebSocket slot to a session. Returns the updated session.
 * Advances status to 'ringing' (first user) or 'active' (second user).
 */
export function addUserToSession(sessionId, uid, ws, lang) {
  const session = sessions.get(sessionId);
  if (!session) throw new Error(`Session ${sessionId} not found`);

  session.slots[uid] = { ws, lang, pipeline: null };

  const count = Object.keys(session.slots).length;
  if (count === 1) {
    session.status = 'ringing';
    session.expiresAt = Date.now() + TTL.ringing;
  } else if (count >= 2) {
    session.status = 'active';
    session.expiresAt = Date.now() + TTL.active;
  }

  return session;
}

/**
 * Remove a user from a session. Destroys their pipeline.
 * If no users remain, deletes the session entirely.
 */
export function removeUserFromSession(sessionId, uid) {
  const session = sessions.get(sessionId);
  if (!session) return;

  session.slots[uid]?.pipeline?.destroy();
  delete session.slots[uid];

  if (Object.keys(session.slots).length === 0) {
    sessions.delete(sessionId);
    console.log(`[sessions] Session ${sessionId} closed (no users remain)`);
  }
}

/** Prune sessions whose TTL has elapsed. Called on a periodic interval. */
export function cleanupExpiredSessions() {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now > session.expiresAt) {
      console.log(`[sessions] Expiring session ${id} (status: ${session.status})`);
      deleteSession(id);
    }
  }
}
