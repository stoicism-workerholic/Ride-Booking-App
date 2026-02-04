
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

setGlobalOptions({region: "us-central1"});

exports.sendNewRideRequestNotification = onDocumentCreated(
    "ride_requests/{rideId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot||snapshot.data().status !== "pending") {
        console.log("No data associated with the event");
        return null;
      }

      const rideId = event.params.rideId;
      const pickup = snapshot.data().pickup; // Get pickup location.
      const dropoff = snapshot.data().dropoff; // Get dropoff location.

      // Fetch all driver tokens from the 'driverTokens' collection.
      const db = getFirestore();
      const driverTokensSnapshot = await db.collection("driverTokens").get();
      const validTokens = [];

      for (const doc of driverTokensSnapshot.docs) {
        const tokenData = doc.data();
        const token = tokenData.token;
        const driverId = doc.id;

        const driverDoc = await db.collection("drivers").doc(driverId).get();
        if (!driverDoc.exists) continue;

        const {notificationsEnabled} = driverDoc.data();
        if (notificationsEnabled === true && token) {
          validTokens.push(token);
        }
      }

      if (validTokens.length === 0) {
        console.log("No drivers available to notify.");
        return null; // Exit if there are no tokens. Important to prevent error
      }

      // Construct the notification payload.
      const payload = {
        notification: {
          title: "New Ride Request",
          body: `Pickup: ${pickup}, Dropoff: ${dropoff}`,
          // sound: "default", // Optiona
        },
        android: {
          notification: {
            sound: "default", // Add sound configuration for Android
          },
        },
        data: {
          // Include the rideId in the data payload, so the driver
          rideId: rideId,
        },
        tokens: validTokens, // Use the tokens array
      };

      // Send the notification to all drivers.
      try {
        const messaging = getMessaging();
        const response = await messaging.sendEachForMulticast(payload);
        console.log(`Successfully notifications to ${response.successCount}`);

        if (response.failureCount > 0) {
          response.responses.forEach((res, idx) => {
            if (!res.success) {
              console.error(`Token failed: ${validTokens[idx]} → ${res.error}`);
            }
          });
        }
      } catch (error) {
        console.error("Error sending notifications:", error);
      }
      return null;
    },
);
