// triggers/quotations.js

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

/**
 * Trigger: jobs/{jobId}/quotations/{quotationId}
 *
 * When a quotation's status changes TO 'accepted':
 *  1. Move the job ref from worker's jobs.applied → jobs.confirmed
 *  2. Reject all OTHER submitted quotations on the same job (auto_rejected = true)
 */
exports.onQuotationAccepted = onDocumentWritten(
  'jobs/{jobId}/quotations/{quotationId}',
  async (event) => {
    const before = event.data.before?.data();
    const after  = event.data.after?.data();

    // Only act when status transitions TO 'accepted'
    const wasAccepted = before?.status === 'accepted';
    const isAccepted  = after?.status  === 'accepted';

    if (wasAccepted || !isAccepted) {
      console.log('ℹ️  No action — not a fresh acceptance.');
      return null;
    }

    const { jobId, quotationId } = event.params;
    const workerUid = after.worker_uid;

    if (!workerUid) {
      console.error('❌ Quotation has no worker_uid — cannot sync.');
      return null;
    }

    console.log(
      `✅ Quotation ${quotationId} accepted for job ${jobId} by worker ${workerUid}`
    );

    const jobRef    = db.collection('jobs').doc(jobId);
    const workerRef = db.collection('workers').doc(workerUid);
    const batch     = db.batch();

    // 1. Move job ref: applied → confirmed
    batch.update(workerRef, {
      'jobs.confirmed': FieldValue.arrayUnion(jobRef),
      'jobs.applied':   FieldValue.arrayRemove(jobRef),
    });

    // 2. Auto-reject other submitted quotations
    const quotationsSnap = await db
      .collection('jobs')
      .doc(jobId)
      .collection('quotations')
      .where('status', '==', 'submitted')
      .get();

    for (const doc of quotationsSnap.docs) {
      if (doc.id === quotationId) continue;

      console.log(`↩️ Auto-rejecting quotation ${doc.id}`);

      batch.update(doc.ref, {
        status:        'rejected',
        auto_rejected: true,
        rejected_at:   FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    console.log(
      `✅ Worker ${workerUid}: applied → confirmed. ${
        quotationsSnap.docs.length - 1
      } other quotations auto-rejected.`
    );

    return null;
  }
);