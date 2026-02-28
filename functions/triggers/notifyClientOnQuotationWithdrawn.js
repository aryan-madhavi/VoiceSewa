const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY CLIENT ON QUOTATION WITHDRAWN ====================
// Fires when a quotation status changes to "withdrawn".
// Sends to the client who owns the job.

exports.notifyClientOnQuotationWithdrawn = onDocumentUpdated(
  "jobs/{jobId}/quotations/{quotationId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const { jobId, quotationId } = event.params;

    // Only act when status changes to withdrawn
    if (before.status === after.status) return;
    if (after.status !== "withdrawn") return;

    const workerName = after.worker_name ?? "A worker";

    console.log(`🚪 Quotation [${quotationId}] withdrawn on job [${jobId}] by ${workerName}`);

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
        title: "Quotation Withdrawn",
        body: `${workerName} has withdrawn their quotation for your ${serviceType} job.`,
      },
      data: {
        type: "quotation_withdrawn",
        job_id: jobId,
        quotation_id: quotationId,
        service_type: serviceType,
      },
    });

    console.log(`✅ Sent [quotation_withdrawn] to client [${clientUid}]:`, response);
  }
);