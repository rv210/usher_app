package com.usherapp.usher_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class UsherDutyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val station = prefs.getString("flutter.widget_duty_station", null) ?: "Sanctuary Main Doors"
            val date = prefs.getString("flutter.widget_duty_date", null) ?: "Next Scheduled Service"
            val role = prefs.getString("flutter.widget_duty_role", null) ?: "USHER"
            val service = prefs.getString("flutter.widget_duty_service", null) ?: "SUNDAY SERVICE"

            val views = RemoteViews(context.packageName, R.layout.widget_usher_duty).apply {
                setTextViewText(R.id.widget_duty_station, station)
                setTextViewText(R.id.widget_duty_date, date)
                setTextViewText(R.id.widget_duty_role_badge, role.uppercase())
                setTextViewText(R.id.widget_duty_service, service.uppercase())

                // Intent to open MainActivity directly into Tab 1 (Roster / Schedule)
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("target_tab", 1)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    1001,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_duty_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, UsherDutyWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
