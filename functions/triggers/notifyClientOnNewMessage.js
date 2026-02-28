const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY CLIENT ON NEW MESSAGE ====================
// Fires when jobs/{jobId}/quotations/{quotationId}/messages/{msgId} is created.
// Only notifies the client when the sender is the WORKER (is_worker == true).
// Includes worker_name in data payload so client router can open ChatScreen directly.

exports.notifyClientOnNewMessage = onDocumentCreated(
  "jobs/{jobId}/quotations/{quotationId}/messages/{msgId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const { jobId, quotationId } = event.params;

    // Only notify client when worker sends a message
    if (message.is_worker !== true) return;

    const senderName = message.sender_name ?? "Worker";
    const originalMsg = message.originalMsg ?? "";

    console.log(`💬 New worker message on job [${jobId}] quotation [${quotationId}]`);

    const db = admin.firestore();

    // ── Fetch job for client_uid and service_type ─────────────────────────
    const jobDoc = await db.collection("jobs").doc(jobId).get();
    if (!jobDoc.exists) {
      console.log(`⚠️ Job [${jobId}] not found`);
      return;
    }

    const job = jobDoc.data();
    const clientUid = job.client_uid;
    const serviceType = job.service_type ?? "Job";

    if (!clientUid) {
      console.log(`⚠️ No client_uid on job [${jobId}]`);
      return;
    }

    // ── Fetch quotation for worker_name ───────────────────────────────────
    const quotationDoc = await db
      .collection("jobs")
      .doc(jobId)
      .collection("quotations")
      .doc(quotationId)
      .get();

    const workerName = quotationDoc.exists
      ? quotationDoc.data().worker_name ?? senderName
      : senderName;

    // ── Fetch client FCM token ────────────────────────────────────────────
    const clientDoc = await db.collection("clients").doc(clientUid).get();
    if (!clientDoc.exists) {
      console.log(`⚠️ Client [${clientUid}] not found`);
      return;
    }

    const fcmToken = clientDoc.data().fcm_token;
    if (!fcmToken) {
      console.log(`⚠️ No FCM token for client [${clientUid}]`);
      return;
    }

    const preview =
      originalMsg.length > 60
        ? originalMsg.substring(0, 57) + "..."
        : originalMsg;

    // ── Send notification ─────────────────────────────────────────────────
    const response = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: `${senderName} — ${serviceType}`,
        body: preview || "New message received",
      },
      data: {
        type: "new_message",
        job_id: jobId,
        quotation_id: quotationId,
        worker_name: workerName,   // ← included so router can open ChatScreen directly
      },
    });

    console.log(`✅ Sent [new_message] to client [${clientUid}]:`, response);
  }
);