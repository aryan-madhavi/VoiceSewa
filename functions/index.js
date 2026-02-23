const { setGlobalOptions } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');

// ── Initialize once here — never in individual trigger files ───────────────
initializeApp();

const { onQuotationAccepted }     = require('./triggers/onQuotationAccepted');
const { onQuotationAutoRejected } = require('./triggers/onQuotationAutoRejected');

setGlobalOptions({ maxInstances: 10 });

exports.onQuotationAccepted     = onQuotationAccepted;
exports.onQuotationAutoRejected = onQuotationAutoRejected;