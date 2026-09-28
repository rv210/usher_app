package com.usherapp.usher_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val BUBBLE_CHANNEL = "com.usherapp.usher_app/bubble"
    private val WIDGET_CHANNEL = "com.usherapp.usher_app/widget"
    private var widgetMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            
            // Primary High Importance Channel (Native Push Notifications)
            val highImportanceChannel = NotificationChannel(
                "high_importance_channel",
                "Guardians Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Urgent notifications for team comms, shift callouts, and station updates"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            manager?.createNotificationChannel(highImportanceChannel)

            // 1. Station & Duty Alerts Channel (Urgent / Heads-up)
            val dutyChannel = NotificationChannel(
                "duty_alerts_channel",
                "Station & Duty Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Urgent station deployments, shift changes, and roster updates"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            manager?.createNotificationChannel(dutyChannel)

            // 2. Leadership Bulletins & Scripture Channel (Default)
            val bulletinChannel = NotificationChannel(
                "bulletin_channel",
                "Leadership Bulletins & Scripture",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Church leadership bulletins and daily devotionals"
                setShowBadge(true)
            }
            manager?.createNotificationChannel(bulletinChannel)
        }
        BubbleNotificationManager.createNotificationChannel(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Bubble Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BUBBLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showBubble" -> {
                    val senderName = call.argument<String>("senderName") ?: "Guardians Team"
                    val message = call.argument<String>("message") ?: ""
                    val senderId = call.argument<String>("senderId") ?: "team_lead"
                    val shortcutId = call.argument<String>("shortcutId") ?: "comms_conversation"
                    val autoExpand = call.argument<Boolean>("autoExpand") ?: false

                    try {
                        BubbleNotificationManager.showBubbleNotification(
                            context = applicationContext,
                            senderName = senderName,
                            messageText = message,
                            senderId = senderId,
                            shortcutId = shortcutId,
                            autoExpand = autoExpand
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BUBBLE_ERROR", e.message, null)
                    }
                }
                "showDutyAlert" -> {
                    val title = call.argument<String>("title") ?: "🔔 Sanctuary Main Doors Assignment"
                    val body = call.argument<String>("body") ?: "You are scheduled for Sanctuary Main Doors (Sunday Morning Service)."
                    val stationName = call.argument<String>("stationName") ?: "Sanctuary Main Doors"
                    val targetTab = call.argument<Int>("targetTab") ?: 0

                    try {
                        DutyNotificationManager.showDutyNotification(
                            context = applicationContext,
                            title = title,
                            body = body,
                            stationName = stationName,
                            targetTab = targetTab
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DUTY_ALERT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Widget Channel
        widgetMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateAllWidgets" -> {
                        try {
                            UsherDutyWidgetProvider.updateAllWidgets(applicationContext)
                            UsherTallyWidgetProvider.updateAllWidgets(applicationContext)
                            UsherScriptureWidgetProvider.updateAllWidgets(applicationContext)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WIDGET_ERROR", e.message, null)
                        }
                    }
                    "getInitialRoute" -> {
                        val initialData = HashMap<String, Any>()
                        if (intent?.hasExtra("target_tab") == true) {
                            initialData["target_tab"] = intent.getIntExtra("target_tab", 0)
                        }
                        if (intent?.hasExtra("target_action") == true) {
                            initialData["target_action"] = intent.getStringExtra("target_action") ?: ""
                        }
                        if (intent?.getStringExtra("route") == "/comms" || intent?.getStringExtra("type") == "comms") {
                            initialData["target_tab"] = 4
                            initialData["target_action"] = "comms"
                        }
                        result.success(initialData)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Check if intent launched with widget deep links or notification intents
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: android.content.Intent?) {
        if (intent == null) return
        val map = HashMap<String, Any>()
        var hasData = false
        if (intent.hasExtra("target_tab")) {
            map["target_tab"] = intent.getIntExtra("target_tab", 0)
            hasData = true
        }
        if (intent.hasExtra("target_action")) {
            map["target_action"] = intent.getStringExtra("target_action") ?: ""
            hasData = true
        }
        if (intent.getStringExtra("route") == "/comms" || intent.getStringExtra("type") == "comms") {
            map["target_tab"] = 4
            map["target_action"] = "comms"
            hasData = true
        }
        if (hasData) {
            widgetMethodChannel?.invokeMethod("onWidgetClick", map)
        }
    }
}

