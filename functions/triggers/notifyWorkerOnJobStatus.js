const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY WORKER ON JOB STATUS CHANGE ====================

exports.notifyWorkerOnJobStatus = onDocumentUpdated(
  "jobs/{jobId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const jobId = event.params.jobId;

    const prevStatus = before.status;
    const newStatus = after.status;

    if (prevStatus === newStatus) return;

    console.log(`🔄 Job [${jobId}] status: ${prevStatus} → ${newStatus}`);

    const workerStatuses = [
      "scheduled",
      "rescheduled",
      "inProgress",
      "completed",
      "cancelled",
    ];
    if (!workerStatuses.includes(newStatus)) return;

    const db = admin.firestore();
    const serviceType = after.service_type ?? "Service";

    // ── Resolve worker_uid via finalized_quotation reference ─────────────
    const finalizedQuotationRef = after.finalized_quotation;

    if (!finalizedQuotationRef) {
      console.log(`⚠️ No finalized_quotation on job [${jobId}], skipping`);
      return;
    }

    const quotationDoc = await finalizedQuotationRef.get();
    if (!quotationDoc.exists) {
      console.log(`⚠️ Finalized quotation not found for job [${jobId}]`);
      return;
    }

    const workerUid = quotationDoc.data().worker_uid;
    if (!workerUid) {
      console.log(`⚠️ Could not resolve worker_uid for job [${jobId}]`);
      return;
    }

    // ── Build notification content ────────────────────────────────────────
    let title, body, type;

    switch (newStatus) {
      case "scheduled":
        title = "Job Confirmed! 🎉";
        body = `Your ${serviceType} job has been scheduled. Check the details.`;
        type = "job_scheduled";
        break;
      case "rescheduled":
        title = "Job Rescheduled 📅";
        body = `Your ${serviceType} job has been rescheduled. Check the new time.`;
        type = "job_rescheduled";
        break;
      case "inProgress":
        title = "Job Started 🔧";
        body = `Your ${serviceType} job is now in progress.`;
        type = "job_update";
        break;
      case "completed":
        title = "Job Completed ✅";
        body = `Your ${serviceType} job has been marked as completed.`;
        type = "job_completed";
        break;
      case "cancelled":
        title = "Job Cancelled ❌";
        body = `The ${serviceType} job has been cancelled by the client.`;
        type = "job_cancelled";
        break;
      default:
        return;
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
      data: { type, job_id: jobId, service_type: serviceType },
    });

    console.log(`✅ Sent [${type}] to worker [${workerUid}]:`, response);
  }
);