const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { Translate } = require("@google-cloud/translate").v2;

setGlobalOptions({ maxInstances: 10, region: "europe-west1"});
admin.initializeApp();
const translate = new Translate();

const LANG_MAP = {
  'en': 'engMsg',
  'hi': 'hinMsg',
  'gu': 'gujMsg',
  'mr': 'marMsg'
};

exports.autoTranslateMessage = onDocumentCreated("chat_rooms/{roomId}/messages/{messageId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const originalText = data.originalMsg;
  if (!originalText) return;

  const sourceLangCode = data.detectedLanguage || 'en';
  let updates = {
    [`translatedLanguages.${LANG_MAP[sourceLangCode]}`]: originalText
  };

  const targetCodes = ['en', 'hi', 'gu', 'mr'];
  const translationPromises = targetCodes.map(async (targetCode) => {
    if (targetCode === sourceLangCode) return;
    try {
      const [translatedText] = await translate.translate(originalText, targetCode);
      updates[`translatedLanguages.${LANG_MAP[targetCode]}`] = translatedText;
    } catch (err) {
      logger.error(`Translation error to ${targetCode}:`, err);
    }
  });

  await Promise.all(translationPromises);
  return snapshot.ref.update(updates);
});