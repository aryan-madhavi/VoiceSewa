const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const Geohash = require("ngeohash");

// ==================== NOTIFY NEARBY WORKERS ====================

exports.notifyNearbyWorkers = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const job = snap.data();
    const jobId = event.params.jobId;

    // ── 1. Validate job data ─────────────────────────────────────
    const jobLocation = job.address?.location;
    if (!jobLocation) {
      console.log("❌ Job has no location, skipping");
      return;
    }

    const serviceType = job.service_type;
    if (!serviceType) {
      console.log("❌ Job has no service_type, skipping");
      return;
    }

    const lat = jobLocation.latitude;
    const lng = jobLocation.longitude;

    console.log(
      `📍 New job [${jobId}] — service: ${serviceType} at ${lat}, ${lng}`
    );

    // ── 2. Compute geohash prefix ────────────────────────────────
    const PRECISION = 5;
    const centerHash = Geohash.encode(lat, lng, PRECISION);

    const neighbors = Geohash.neighbors(centerHash);
    const cellsToCheck = [centerHash, ...Object.values(neighbors)];

    console.log(`🔍 Checking ${cellsToCheck.length} cells`);

    const db = admin.firestore();
    const matchedWorkers = new Map();

    // ── 3. Query workers by geohash ──────────────────────────────
    await Promise.all(
      cellsToCheck.map(async (cell) => {
        const snapshot = await db
          .collection("workers")
          .where("address.geohash", ">=", cell)
          .where("address.geohash", "<", cell + "\uf8ff")
          .get();

        snapshot.forEach((doc) => {
          const worker = doc.data();

          if (matchedWorkers.has(doc.id)) return;
          if (!worker.fcm_token) return;

          const skills = worker.skills ?? [];
          if (!skills.includes(serviceType)) return;

          matchedWorkers.set(doc.id, {
            fcm_token: worker.fcm_token,
          });
        });
      })
    );

    if (matchedWorkers.size === 0) {
      console.log("⚠️ No nearby workers found");
      return;
    }

    const workerIds = [...matchedWorkers.keys()];
    const fcmTokens = [...matchedWorkers.values()].map((w) => w.fcm_token);

    console.log(`📢 Sending to ${fcmTokens.length} workers`);

    // ── 4. Send FCM ──────────────────────────────────────────────
    const message = {
      notification: {
        title: "New Job Nearby! 🔔",
        body: `A new ${serviceType} job is available near you.`,
      },
      data: {
        job_id: jobId,
        service_type: serviceType,
        type: "new_job",
      },
      tokens: fcmTokens,
    };

    const response = await admin
      .messaging()
      .sendEachForMulticast(message);

    console.log(
      `✅ Sent: ${response.successCount} | ❌ Failed: ${response.failureCount}`
    );

    // ── 5. Clean invalid tokens ───────────────────────────────────
    await Promise.all(
      response.responses.map(async (result, index) => {
        if (!result.success) {
          const errorCode = result.error?.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            const workerId = workerIds[index];
            await db.collection("workers").doc(workerId).update({
              fcm_token: admin.firestore.FieldValue.delete(),
            });

            console.log(`🧹 Removed invalid token from ${workerId}`);
          }
        }
      })
    );
  }
);