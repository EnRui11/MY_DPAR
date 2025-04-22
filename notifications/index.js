/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Initialize Firebase Admin
initializeApp();

// Function to process notifications from the notification_queue collection
exports.processNotificationQueue = onDocumentCreated(
  "notification_queue/{notificationId}",
  async (event) => {
    // Get the notification data
    const notification = event.data.data();
    const notificationId = event.params.notificationId;

    try {
      // Log the start of processing
      logger.info(`Processing notification ${notificationId}`, {notification});

      // Validate notification data
      if (!notification.token || !notification.notification) {
        throw new Error("Missing required notification data");
      }

      // Prepare the FCM message
      const message = {
        token: notification.token,
        notification: {
          title: notification.notification.title,
          body: notification.notification.body,
        },
        data: notification.data || {},
        android: {
          priority: "high",
          notification: {
            channelId: "emergency_alerts",
            priority: "max",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              priority: 10,
            },
          },
        },
      };

      // Send the FCM message
      const response = await getMessaging().send(message);

      // Update document with success status
      await event.data.ref.update({
        status: "sent",
        sentAt: new Date().toISOString(),
        fcmResponse: response,
      });

      logger.info(`Successfully sent notification ${notificationId}`, {response});
      return {success: true, messageId: response};
    } catch (error) {
      // Log the error
      logger.error(`Error sending notification ${notificationId}:`, error);

      // Update document with error status
      await event.data.ref.update({
        status: "error",
        error: error.message,
        errorAt: new Date().toISOString(),
      });

      // Re-throw the error to mark the function as failed
      throw error;
    }
  },
);
