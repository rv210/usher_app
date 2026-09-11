package com.usherapp.usher_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.content.LocusIdCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

object BubbleNotificationManager {
    const val CHANNEL_ID = "comms_bubble_channel"
    const val CHANNEL_NAME = "Guardians Team Comms"

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Team chat messages and instant conversation bubbles"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    setAllowBubbles(true)
                }
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    fun showBubbleNotification(
        context: Context,
        senderName: String,
        messageText: String,
        senderId: String = "team_lead",
        shortcutId: String = "comms_conversation",
        timestamp: Long = System.currentTimeMillis()
    ) {
        // Ensure notification channel is created
        createNotificationChannel(context)

        val appIcon = IconCompat.createWithResource(context, R.mipmap.ic_launcher)

        // 1. Sender Person
        val senderPerson = Person.Builder()
            .setName(senderName)
            .setKey(senderId)
            .setImportant(true)
            .setIcon(appIcon)
            .build()

        // 2. Intent to open inside the bubble container (targeting BubbleActivity)
        val bubbleActivityIntent = Intent(context, BubbleActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra("route", "/comms")
            putExtra("shortcutId", shortcutId)
            putExtra("senderName", senderName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        // 3. Register long-lived dynamic shortcut for Android 11+ conversation space
        val shortcut = ShortcutInfoCompat.Builder(context, shortcutId)
            .setLocusId(LocusIdCompat(shortcutId))
            .setActivity(ComponentName(context, BubbleActivity::class.java))
            .setShortLabel(senderName)
            .setLongLabel("Chat with $senderName")
            .setLongLived(true)
            .setIcon(appIcon)
            .setPerson(senderPerson)
            .setIntent(bubbleActivityIntent)
            .build()

        ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)

        // 4. PendingIntent for the Bubble
        val bubblePendingIntent = PendingIntent.getActivity(
            context,
            shortcutId.hashCode(),
            bubbleActivityIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        // 5. Standard Content Intent (when user taps the notification header rather than bubble)
        val contentIntent = PendingIntent.getActivity(
            context,
            shortcutId.hashCode() + 1,
            Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("route", "/comms")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        // 6. Construct BubbleMetadata
        val bubbleMetadata = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ (API 30+) recommended constructor with shortcutId
            NotificationCompat.BubbleMetadata.Builder(shortcutId)
                .setDesiredHeight(600)
                .setAutoExpandBubble(true)
                .setSuppressNotification(false)
                .build()
        } else {
            // Android 10 (API 29) fallback constructor with PendingIntent
            NotificationCompat.BubbleMetadata.Builder(bubblePendingIntent, appIcon)
                .setDesiredHeight(600)
                .setAutoExpandBubble(true)
                .setSuppressNotification(false)
                .build()
        }

        // 7. MessagingStyle conversation
        val currentUser = Person.Builder()
            .setName("Me")
            .setKey("current_user")
            .build()

        val messagingStyle = NotificationCompat.MessagingStyle(currentUser)
            .setConversationTitle("Guardians Comms")
            .setGroupConversation(true)
            .addMessage(
                NotificationCompat.MessagingStyle.Message(
                    messageText,
                    timestamp,
                    senderPerson
                )
            )

        // 8. NotificationCompat Builder adhering to Android Design Guidelines
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setColor(androidx.core.content.ContextCompat.getColor(context, R.color.widget_gold_primary))
            .setContentTitle(senderName)
            .setContentText(messageText)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setShortcutId(shortcutId)
            .setLocusId(LocusIdCompat(shortcutId))
            .setStyle(messagingStyle)
            .setBubbleMetadata(bubbleMetadata)
            .setContentIntent(contentIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setGroup("guardians_comms_group")
            .setAutoCancel(true)
            .setShowWhen(true)
            .addAction(
                R.drawable.ic_stat_notification,
                "Open Chat",
                contentIntent
            )
            .build()

        val notificationId = (shortcutId.hashCode() and 0x7FFFFFFF)
        try {
            android.util.Log.d("BubbleNotification", "Dispatching bubble notification id=$notificationId")
            NotificationManagerCompat.from(context).notify(notificationId, notification)
            android.util.Log.d("BubbleNotification", "Successfully posted bubble notification")
        } catch (e: Exception) {
            android.util.Log.e("BubbleNotification", "Error notifying bubble: ${e.message}", e)
        }
    }
}
