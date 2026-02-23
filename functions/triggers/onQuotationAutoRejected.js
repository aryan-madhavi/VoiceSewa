// triggers/onQuotationAutoRejected.js

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const db = getFirestore();

/**
 * Trigger: jobs/{jobId}/quotations/{quotationId}
 *
 * When a quotation is auto-rejected (i.e. another worker's was accepted),
 * moves the job ref from the losing worker's jobs.applied → jobs.declined.
 *
 * NOTE: initializeApp() is already called in index.js — do NOT call it here.
 */
exports.onQuotationAutoRejected = onDocumentUpdated(
  'jobs/{jobId}/quotations/{quotationId}',
  async (event) => {
    const before = event.data.before?.data();
    const after  = event.data.after?.data();

    // Only act when:
    //  - status just changed TO 'rejected'
    //  - AND it was auto-rejected (not manually rejected by client)
    const wasRejected  = before?.status === 'rejected';
    const isRejected   = after?.status  === 'rejected';
    const isAutoReject = after?.auto_rejected === true;

    if (wasRejected || !isRejected || !isAutoReject) {
      return null;
    }

    const { jobId, quotationId } = event.params;
    const workerUid = after.worker_uid;

    if (!workerUid) {
      console.error(`❌ [onQuotationAutoRejected] Quotation ${quotationId} has no worker_uid — skipping.`);
      return null;
    }

    console.log(
      `↩️  [onQuotationAutoRejected] Quotation ${quotationId} auto-rejected — ` +
      `moving job ${jobId} from applied → declined for worker ${workerUid}`
    );

    const jobRef    = db.collection('jobs').doc(jobId);
    const workerRef = db.collection('workers').doc(workerUid);

    await workerRef.update({
      'jobs.applied':  FieldValue.arrayRemove(jobRef),
      'jobs.declined': FieldValue.arrayUnion(jobRef),
    });

    console.log(`✅ [onQuotationAutoRejected] Worker ${workerUid}: applied → declined for job ${jobId}`);

    return null;
  }
);