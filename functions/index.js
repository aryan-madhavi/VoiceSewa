const { setGlobalOptions } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');

// ── Initialize once here — never in individual trigger files ───────────────
initializeApp();

setGlobalOptions({ maxInstances: 10 });

// ── Worker notifications ───────────────────────────────────────────────────
const { notifyNearbyWorkers }          = require('./triggers/notifyNearbyWorkers');
const { notifyWorkerOnJobStatus }      = require('./triggers/notifyWorkerOnJobStatus');
const { notifyWorkerOnQuotationStatus} = require('./triggers/notifyWorkerOnQuotationStatus');
const { notifyWorkerOnNewMessage }     = require('./triggers/notifyWorkerOnNewMessage');

// ── Client notifications ───────────────────────────────────────────────────
const { notifyClientOnNewQuotation }      = require('./triggers/notifyClientOnNewQuotation');
const { notifyClientOnQuotationWithdrawn }= require('./triggers/notifyClientOnQuotationWithdrawn');
const { notifyClientOnNewMessage }        = require('./triggers/notifyClientOnNewMessage');
const { notifyClientOnJobStatus }         = require('./triggers/notifyClientOnJobStatus');

// ── Other triggers ─────────────────────────────────────────────────────────
const { onQuotationAccepted }          = require('./triggers/onQuotationAccepted');
const { onQuotationAutoRejected }      = require('./triggers/onQuotationAutoRejected');
const { recalculateWorkerAvgRating }   = require('./triggers/Recalculateworkeravgrating');

module.exports = {
  // worker
  notifyNearbyWorkers,
  notifyWorkerOnJobStatus,
  notifyWorkerOnQuotationStatus,
  notifyWorkerOnNewMessage,
  // client
  notifyClientOnNewQuotation,
  notifyClientOnQuotationWithdrawn,
  notifyClientOnNewMessage,
  notifyClientOnJobStatus,
  // other
  onQuotationAccepted,
  onQuotationAutoRejected,
  recalculateWorkerAvgRating,
};