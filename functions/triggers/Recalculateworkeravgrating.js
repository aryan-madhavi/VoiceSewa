const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');

const db = getFirestore();

/**
 * Recalculates a worker's avg_rating whenever a job's client_feedback changes.
 *
 * Only jobs listed in the worker's jobs.completed references are considered.
 */
const recalculateWorkerAvgRating = onDocumentWritten(
  'jobs/{jobId}',
  async (event) => {
    const jobId = event.params.jobId;
    const afterData = event.data?.after?.data();
    const beforeData = event.data?.before?.data();

    // ── Guard: only proceed if client_feedback.rating actually changed ───────
    const ratingBefore = beforeData?.client_feedback?.rating ?? null;
    const ratingAfter  = afterData?.client_feedback?.rating  ?? null;

    if (ratingBefore === ratingAfter) return null;

    console.log(`[recalculateWorkerAvgRating] client_feedback changed on job ${jobId}`);

    // ── Find the worker who has this job in jobs.completed ───────────────────
    const jobRef = db.collection('jobs').doc(jobId);

    const workersSnap = await db
      .collection('workers')
      .where('jobs.completed', 'array-contains', jobRef)
      .get();

    if (workersSnap.empty) {
      console.log(`No worker found with job ${jobId} in jobs.completed. Skipping.`);
      return null;
    }

    // Process all matching workers (should normally be exactly one)
    await Promise.all(
      workersSnap.docs.map(async (workerDoc) => {
        const completedRefs = workerDoc.data()?.jobs?.completed ?? [];

        if (completedRefs.length === 0) {
          await workerDoc.ref.update({ avg_rating: 0 });
          return;
        }

        console.log(
          `Worker ${workerDoc.id} — fetching ${completedRefs.length} completed job(s)`
        );

        // ── Fetch all completed jobs (batches of 30 — Firestore getAll limit) ─
        const ratings = [];
        const batchSize = 30;

        for (let i = 0; i < completedRefs.length; i += batchSize) {
          const batch = completedRefs.slice(i, i + batchSize);
          const jobDocs = await db.getAll(...batch);

          for (const jobDoc of jobDocs) {
            if (!jobDoc.exists) continue;
            const rating = jobDoc.data()?.client_feedback?.rating;
            if (typeof rating === 'number' && !isNaN(rating)) {
              ratings.push(rating);
            }
          }
        }

        if (ratings.length === 0) {
          console.log(`Worker ${workerDoc.id} — no rated completed jobs found`);
          await workerDoc.ref.update({ avg_rating: 0 });
          return;
        }

        // ── Average and write back ────────────────────────────────────────────
        const avg =
          Math.round(
            (ratings.reduce((acc, r) => acc + r, 0) / ratings.length) * 10
          ) / 10; // 1 decimal place

        await workerDoc.ref.update({ avg_rating: avg });
        console.log(
          `Worker ${workerDoc.id} — avg_rating updated to ${avg} (${ratings.length} ratings)`
        );
      })
    );

    return null;
  }
);

module.exports = { recalculateWorkerAvgRating };