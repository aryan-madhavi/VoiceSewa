const { setGlobalOptions } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');

// ── Initialize once here — never in individual trigger files ───────────────
initializeApp();

const { onQuotationAccepted }     = require('./triggers/onQuotationAccepted');
const { onQuotationAutoRejected } = require('./triggers/onQuotationAutoRejected');
const { recalculateWorkerAvgRating } = require('./triggers/Recalculateworkeravgrating')
const { notifyNearbyWorkers } = require('./triggers/notifyNearbyWorkers');
const { notifyWorkerOnJobStatus } = require("./triggers/notifyWorkerOnJobStatus");
const { notifyWorkerOnQuotationStatus } = require("./triggers/notifyWorkerOnQuotationStatus");
const { notifyWorkerOnNewMessage } = require("./triggers/notifyWorkerOnNewMessage");


setGlobalOptions({ maxInstances: 10 });

exports.onQuotationAccepted     = onQuotationAccepted;
exports.onQuotationAutoRejected = onQuotationAutoRejected;
exports.recalculateWorkerAvgRating = recalculateWorkerAvgRating;
exports.notifyNearbyWorkers = notifyNearbyWorkers;
exports.notifyWorkerOnJobStatus = notifyWorkerOnJobStatus;
exports.notifyWorkerOnQuotationStatus = notifyWorkerOnQuotationStatus;
exports.notifyWorkerOnNewMessage = notifyWorkerOnNewMessage;