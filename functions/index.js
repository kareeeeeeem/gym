const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// ✅ initialize Firebase Admin SDK
admin.initializeApp();

// ✅ إعداد بيانات OneSignal
const ONE_SIGNAL_APP_ID = "e17ceb1e-09d4-41d4-aee4-91cdee1b1d6b"; // App ID بتاعك
const ONE_SIGNAL_REST_API_KEY = "YOUR_REST_API_KEY_HERE"; // ضع الـ REST API Key من OneSignal Dashboard

// ✅ دالة إرسال الإشعارات لكل المستخدمين
exports.sendNotificationToAll = functions.https.onRequest(async (req, res) => {
  try {
    const { title, message } = req.body;

    const response = await axios.post(
      "https://onesignal.com/api/v1/notifications",
      {
        app_id: ONE_SIGNAL_APP_ID,
        included_segments: ["All"], // يرسل لكل المستخدمين
        headings: { en: title || "New Notification" },
        contents: { en: message || "Check out the latest update!" },
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${ONE_SIGNAL_REST_API_KEY}`,
        },
      }
    );

    console.log("✅ Notification sent:", response.data);
    res.status(200).send("Notification sent successfully!");
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    res.status(500).send("Failed to send notification.");
  }
});
