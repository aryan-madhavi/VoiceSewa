import admin from 'firebase-admin';

/**
 * Verify a Firebase ID token.
 * @param {string} token
 * @param {{ checkRevoked?: boolean }} options
 * @returns {Promise<admin.auth.DecodedIdToken>}
 */
export async function verifyToken(token, { checkRevoked = true } = {}) {
  return admin.auth().verifyIdToken(token, checkRevoked);
}
