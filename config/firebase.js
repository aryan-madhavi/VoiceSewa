import admin from 'firebase-admin';
import serviceAccount from '../ServiceAccountKey.json' with { type: 'json' };

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
})

const db = admin.firestore();
const auth = admin.auth();

export { db, auth };
export default admin;