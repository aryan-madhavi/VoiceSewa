const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

module.exports = onDocumentCreated(
  "service_requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const requestData = snap.data();
    const requestId = event.params.requestId;

    console.log("🆕 New service request created:", requestId);

    try {
      const message = {
        notification: {
          title: "🆕 New Job Available!",
          body: `New ${requestData.serviceType || "service"} request in ${
            requestData.location || "your area"
          }`,
        },
        data: {
          type: "new_job",
          requestId,
          serviceType: requestData.serviceType || "",
          location: requestData.location || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "job_notifications",
            color: "#FF6B35",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        topic: "workers",
      };

      const response = await admin.messaging().send(message);
      console.log("✅ Notification sent:", response);

      return response;
    } catch (error) {
      console.error("❌ Error sending notification:", error);
    }
  }
);
