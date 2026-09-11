package com.usherapp.usher_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

object DutyNotificationManager {
    const val CHANNEL_ID = "duty_alerts_channel"
    const val CHANNEL_NAME = "Station & Duty Alerts"
    const val NOTIFICATION_ID = 20260907

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Urgent station deployments, shift changes, and roster updates"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    fun showDutyNotification(
        context: Context,
        title: String,
        body: String,
        stationName: String = "Sanctuary Main Doors",
        targetTab: Int = 0
    ) {
        createNotificationChannel(context)

        // 1. Content Intent - Tapping notification opens Roster tab directly
        val contentIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("target_tab", targetTab)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        // 2. Action: View Station
        val viewStationAction = NotificationCompat.Action.Builder(
            R.drawable.ic_stat_notification,
            "View Station",
            contentIntent
        ).build()

        // 3. Action: Confirm Shift
        val confirmIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID + 1,
            Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("target_tab", targetTab)
                putExtra("confirmed_shift", true)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        val confirmAction = NotificationCompat.Action.Builder(
            R.drawable.ic_stat_notification,
            "Confirm Shift",
            confirmIntent
        ).build()

        // 4. BigTextStyle adhering to Android Guidelines
        val bigTextStyle = NotificationCompat.BigTextStyle()
            .setBigContentTitle(title)
            .bigText(body)
            .setSummaryText("Station Deployment")

        // 5. Build Notification
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setColor(ContextCompat.getColor(context, R.color.widget_gold_primary))
            .setContentTitle(title)
            .setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setStyle(bigTextStyle)
            .setContentIntent(contentIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setGroup("guardians_duty_group")
            .setAutoCancel(true)
            .setShowWhen(true)
            .addAction(viewStationAction)
            .addAction(confirmAction)
            .build()

        try {
            android.util.Log.d("DutyNotification", "Dispatching duty notification id=$NOTIFICATION_ID")
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
            android.util.Log.d("DutyNotification", "Successfully posted duty notification")
        } catch (e: Exception) {
            android.util.Log.e("DutyNotification", "Error notifying duty alert: ${e.message}", e)
        }
    }
}
