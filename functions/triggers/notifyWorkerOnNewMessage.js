const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY WORKER ON NEW MESSAGE ====================

exports.notifyWorkerOnNewMessage = onDocumentCreated(
  "jobs/{jobId}/quotations/{quotationId}/messages/{msgId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const { jobId, quotationId } = event.params;

    // Only notify worker when client sends a message
    if (message.is_worker === true) return;

    const senderName = message.sender_name ?? "Client";
    const originalMsg = message.originalMsg ?? "";

    console.log(`💬 New client message on job [${jobId}] quotation [${quotationId}]`);

    const db = admin.firestore();

    // ── Get worker_uid from quotation ─────────────────────────────────────
    const quotationDoc = await db
      .collection("jobs")
      .doc(jobId)
      .collection("quotations")
      .doc(quotationId)
      .get();

    if (!quotationDoc.exists) {
      console.log(`⚠️ Quotation [${quotationId}] not found`);
      return;
    }

    const workerUid = quotationDoc.data().worker_uid;
    if (!workerUid) {
      console.log(`⚠️ No worker_uid on quotation [${quotationId}]`);
      return;
    }

    // ── Fetch job for service_type ────────────────────────────────────────
    const jobDoc = await db.collection("jobs").doc(jobId).get();
    const serviceType = jobDoc.exists
      ? jobDoc.data().service_type ?? "Job"
      : "Job";

    // ── Fetch worker FCM token and send ───────────────────────────────────
    const workerDoc = await db.collection("workers").doc(workerUid).get();
    if (!workerDoc.exists) {
      console.log(`⚠️ Worker [${workerUid}] not found`);
      return;
    }

    const fcmToken = workerDoc.data().fcm_token;
    if (!fcmToken) {
      console.log(`⚠️ No FCM token for worker [${workerUid}]`);
      return;
    }

    const preview =
      originalMsg.length > 60 ? originalMsg.substring(0, 57) + "..." : originalMsg;

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
      },
    });

    console.log(`✅ Sent [new_message] to worker [${workerUid}]:`, response);
  }
);