package com.usherapp.usher_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Dedicated activity for Android Bubble Notifications.
 * Configured with allowEmbedded="true", resizeableActivity="true",
 * and documentLaunchMode="always" in AndroidManifest.xml.
 */
class BubbleActivity : FlutterFragmentActivity() {
    override fun getInitialRoute(): String {
        val route = intent?.getStringExtra("route")
        return if (!route.isNullOrBlank()) route else "/comms"
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
