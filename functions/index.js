const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const { onQuotationAccepted } = require('./triggers/onQuotationAccepted');

setGlobalOptions({ maxInstances: 10 });

exports.onQuotationAccepted = onQuotationAccepted;