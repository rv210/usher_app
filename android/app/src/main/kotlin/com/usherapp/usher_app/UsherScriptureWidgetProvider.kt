package com.usherapp.usher_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class UsherScriptureWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val text = prefs.getString(
                "flutter.widget_scripture_text",
                null
            ) ?: "Better is one day in your courts than a thousand elsewhere; I would rather be a doorkeeper in the house of my God..."
            val ref = prefs.getString("flutter.widget_scripture_ref", null) ?: "— Psalm 84:10 (NIV)"
            val category = prefs.getString("flutter.widget_scripture_category", null) ?: "MINISTRY"

            val views = RemoteViews(context.packageName, R.layout.widget_usher_scripture).apply {
                setTextViewText(R.id.widget_scripture_text, "\"$text\"")
                setTextViewText(R.id.widget_scripture_ref, ref)
                setTextViewText(R.id.widget_scripture_category, category.uppercase())

                // Intent to open MainActivity and trigger the Handbook view
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("target_action", "handbook")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    1003,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_scripture_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, UsherScriptureWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
