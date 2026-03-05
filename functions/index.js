const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp }     = require('firebase-admin/app');
const { getMessaging }      = require('firebase-admin/messaging');

initializeApp();

exports.sendCallNotification = onDocumentCreated(
  {
    document: 'calls/{sessionId}',
    region:   'asia-south1',
  },
  async (event) => {
    const data      = event.data.data();
    const sessionId = event.params.sessionId;

    // Only fire on a freshly created ringing call
    if (data.status !== 'ringing') return null;

    const token = data.receiverFcmToken;
    if (!token) {
      console.warn(`No FCM token for session ${sessionId}`);
      return null;
    }

    try {
      await getMessaging().send({
        token,
        data: {
          type:         'incoming_call',
          sessionId,
          callerUid:    data.callerUid    ?? '',
          callerName:   data.callerName   ?? 'Unknown',
          callerLang:   data.callerLang   ?? 'hi-IN',
          receiverLang: data.receiverLang ?? 'en-IN',
        },
        android: {
          priority: 'high',
        },
        apns: {
          headers: { 'apns-priority': '10' },
          payload: {
            aps: {
              contentAvailable: true,
              sound: 'default',
            },
          },
        },
      });
      console.log(`Call notification sent for session ${sessionId}`);
    } catch (err) {
      console.error(`Failed to send notification for session ${sessionId}:`, err);
    }

    return null;
  }
);