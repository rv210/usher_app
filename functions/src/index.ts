import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

initializeApp();

function getAdmin() {
  return {
    db: getFirestore(),
    messaging: getMessaging(),
  };
}

async function sendPushToTokens({
  title,
  body,
  data = {},
  excludeUid = "",
}: {
  title: string;
  body: string;
  data?: Record<string, string>;
  excludeUid?: string;
}) {
  const { db, messaging } = getAdmin();

  const payload = {
    notification: { title, body },
    data: {
      ...data,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high" as const,
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
        priority: "high" as const,
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          sound: "default",
          badge: 1,
          "content-available": 1,
        },
      },
    },
  };

  // Multicast to registered user_tokens. This is the only delivery path -
  // every device that completes push init both subscribes to the FCM
  // topics AND stores its token here, so sending to both would double-fire.
  try {
    const tokensSnap = await db.collection("user_tokens").get();
    const tokenSet = new Set<string>();
    tokensSnap.forEach((doc) => {
      const docData = doc.data();
      const token = docData.token || docData.fcmToken;
      if (token && typeof token === "string" && (!excludeUid || doc.id !== excludeUid)) {
        tokenSet.add(token.trim());
      }
    });

    const tokens = Array.from(tokenSet);

    if (tokens.length > 0) {
      const chunkSize = 500;
      for (let i = 0; i < tokens.length; i += chunkSize) {
        const chunk = tokens.slice(i, i + chunkSize);
        const res = await messaging.sendEachForMulticast({ tokens: chunk, ...payload });
        logger.info(`Multicast (${chunk.length} unique tokens): ${res.successCount} ok, ${res.failureCount} failed`);
      }
    }
  } catch (err) {
    logger.error("Error sending token multicast:", err);
  }
}

/** 1. Comms Messages */
export const onNewCommsMessage = onDocumentCreated(
  "communications/{msgId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.text) return;

    const authorName = data.authorName || "Team Member";
    const text = data.text;
    const authorUid = data.authorUid || "";

    await sendPushToTokens({
      title: authorName,
      body: text,
      data: { type: "comms", msgId: event.params.msgId },
      excludeUid: authorUid,
    });
  }
);

/** 2. Deployment / Schedule Published */
export const sendDeploymentPublishedNotification = onDocumentCreated(
  "deployment_publishes/{depId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const usherName = data.usherName || "Usher";
    const station = data.station || "Station";
    const date = data.date || "Upcoming Service";

    await sendPushToTokens({
      title: "New Duty Assignment",
      body: `Assigned ${usherName} to ${station} for ${date}`,
      data: { type: "schedule", depId: event.params.depId },
    });
  }
);

/** 2b. Deployment Sub-In (subInDeployment merges into an existing
 * deployment_publishes doc, so this fires as an update, not a create) */
export const sendDeploymentSubInNotification = onDocumentUpdated(
  "deployment_publishes/{depId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || !after.usherName) return;
    if (before.usherName === after.usherName) return;

    await sendPushToTokens({
      title: "Schedule Sub-In Update",
      body: `${after.usherName} subbed in for ${before.usherName || "a teammate"} at ${after.station || "their station"}`,
      data: { type: "schedule", depId: event.params.depId },
    });
  }
);

/** 3. Attendance Submitted */
export const sendAttendanceNotification = onDocumentCreated(
  "attendance_logs/{logId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const headcount = data.headcount || 0;
    const serviceType = data.serviceType || "Service";
    const submittedBy = data.submittedBy || "Usher";

    await sendPushToTokens({
      title: `Attendance Logged: ${headcount}`,
      body: `${serviceType} headcount (${headcount}) submitted by ${submittedBy}`,
      data: { type: "attendance", logId: event.params.logId },
    });
  }
);

/** 4. Registration Approval Status */
export const onRegistrationApproved = onDocumentUpdated(
  "team/{userId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Trigger if approved changed from false to true
    if (!before.approved && after.approved) {
      const { db, messaging } = getAdmin();
      const userName = after.name || "Usher";
      const tokenDoc = await db.collection("user_tokens").doc(event.params.userId).get();
      const token = tokenDoc.data()?.token || tokenDoc.data()?.fcmToken;

      if (token) {
        try {
          await messaging.send({
            token,
            notification: {
              title: "Registration Approved!",
              body: `Welcome to the Guardians team, ${userName}! You now have full access to the Usher Hub.`,
            },
            data: { type: "approval" },
            apns: { payload: { aps: { sound: "default", badge: 1 } } },
            android: { notification: { channelId: "high_importance_channel", sound: "default" } },
          });
          logger.info(`Approval push sent to ${userName}`);
        } catch (err) {
          logger.error("Error sending approval push:", err);
        }
      }
    }
  }
);

/** 5. Broadcast Bulletin Updated (the doc already exists in production,
 * so client edits land as update events, not create events) */
export const onBroadcastMessageUpdated = onDocumentUpdated(
  "settings/bulletin",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after || !after.text || before?.text === after.text) return;
    const data = after;

    await sendPushToTokens({
      title: "New Bulletin Announcement",
      body: data.text,
      data: { type: "bulletin" },
    });
  }
);
