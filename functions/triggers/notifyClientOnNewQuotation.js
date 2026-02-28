const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY CLIENT ON NEW QUOTATION ====================
// Fires when a new quotation is submitted on a job.
// Sends to the client who owns the job.

exports.notifyClientOnNewQuotation = onDocumentCreated(
  "jobs/{jobId}/quotations/{quotationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const quotation = snap.data();
    const { jobId, quotationId } = event.params;

    const workerName = quotation.worker_name ?? "A worker";

    console.log(`📋 New quotation [${quotationId}] on job [${jobId}] from ${workerName}`);

    const db = admin.firestore();

    // ── Fetch job for client_uid and service_type ─────────────────────────
    const jobDoc = await db.collection("jobs").doc(jobId).get();
    if (!jobDoc.exists) {
      console.log(`⚠️ Job [${jobId}] not found`);
      return;
    }

    const job = jobDoc.data();
    const clientUid = job.client_uid;
    const serviceType = job.service_type ?? "Service";

    if (!clientUid) {
      console.log(`⚠️ No client_uid on job [${jobId}]`);
      return;
    }

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

    const response = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "New Quotation Received! 📋",
        body: `${workerName} submitted a quotation for your ${serviceType} job.`,
      },
      data: {
        type: "new_quotation",
        job_id: jobId,
        quotation_id: quotationId,
        service_type: serviceType,
      },
    });

    console.log(`✅ Sent [new_quotation] to client [${clientUid}]:`, response);
  }
);