const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY WORKER ON QUOTATION STATUS CHANGE ====================

exports.notifyWorkerOnQuotationStatus = onDocumentUpdated(
  "jobs/{jobId}/quotations/{quotationId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const { jobId, quotationId } = event.params;

    const prevStatus = before.status;
    const newStatus = after.status;

    if (prevStatus === newStatus) return;

    console.log(
      `📋 Quotation [${quotationId}] on job [${jobId}]: ${prevStatus} → ${newStatus}`
    );

    if (!["accepted", "rejected"].includes(newStatus)) return;

    const workerUid = after.worker_uid;
    if (!workerUid) {
      console.log(`⚠️ No worker_uid on quotation [${quotationId}], skipping`);
      return;
    }

    const db = admin.firestore();

    // ── Fetch job for service_type ────────────────────────────────────────
    const jobDoc = await db.collection("jobs").doc(jobId).get();
    const serviceType = jobDoc.exists
      ? jobDoc.data().service_type ?? "Service"
      : "Service";

    // ── Build notification content ────────────────────────────────────────
    let title, body, type;

    if (newStatus === "accepted") {
      title = "Quotation Accepted! 🎉";
      body = `Your quotation for the ${serviceType} job has been accepted. Get ready!`;
      type = "quotation_accepted";
    } else {
      const isAuto = after.auto_rejected === true;
      title = isAuto ? "Quotation Auto-Rejected" : "Quotation Rejected";
      body = isAuto
        ? `Another worker was selected for the ${serviceType} job.`
        : `Your quotation for the ${serviceType} job was not selected.`;
      type = "quotation_rejected";
    }

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

    const response = await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: { type, job_id: jobId, quotation_id: quotationId, service_type: serviceType },
    });

    console.log(`✅ Sent [${type}] to worker [${workerUid}]:`, response);
  }
);