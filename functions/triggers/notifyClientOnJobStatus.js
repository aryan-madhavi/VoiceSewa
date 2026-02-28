const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// ==================== NOTIFY CLIENT ON JOB STATUS CHANGE ====================
// Fires when jobs/{jobId} is updated.
// Covers: inProgress, completed.
// Client already knows about: scheduled (they accepted), cancelled (they did it).

exports.notifyClientOnJobStatus = onDocumentUpdated(
  "jobs/{jobId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const jobId = event.params.jobId;

    const prevStatus = before.status;
    const newStatus = after.status;

    if (prevStatus === newStatus) return;

    console.log(`🔄 Job [${jobId}] status: ${prevStatus} → ${newStatus}`);

    const clientStatuses = ["inProgress", "completed"];
    if (!clientStatuses.includes(newStatus)) return;

    const clientUid = after.client_uid;
    if (!clientUid) {
      console.log(`⚠️ No client_uid on job [${jobId}]`);
      return;
    }

    const serviceType = after.service_type ?? "Service";
    const workerName = after.worker_name ?? "Your worker";

    // ── Build notification content ────────────────────────────────────────
    let title, body, type;

    switch (newStatus) {
      case "inProgress":
        title = "Work Has Started! 🔧";
        body = `${workerName} has started your ${serviceType} job.`;
        type = "job_started";
        break;

      case "completed":
        title = "Job Completed ✅";
        body = `${workerName} has completed your ${serviceType} job. Please review the bill.`;
        type = "job_completed";
        break;

      default:
        return;
    }

    // ── Fetch client FCM token ────────────────────────────────────────────
    const db = admin.firestore();
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
      notification: { title, body },
      data: { type, job_id: jobId, service_type: serviceType },
    });

    console.log(`✅ Sent [${type}] to client [${clientUid}]:`, response);
  }
);