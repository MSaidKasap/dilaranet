package com.dilara.social

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val fajr = prefs.getString("flutter.widget_fajr", "") ?: ""
            if (fajr.isNotEmpty()) {
                PrayerNotificationService.startOrUpdate(
                    context = context,
                    fajrVal = fajr,
                    sunriseVal = prefs.getString("flutter.widget_sunrise", "") ?: "",
                    dhuhrVal = prefs.getString("flutter.widget_dhuhr", "") ?: "",
                    asrVal = prefs.getString("flutter.widget_asr", "") ?: "",
                    maghribVal = prefs.getString("flutter.widget_maghrib", "") ?: "",
                    ishaVal = prefs.getString("flutter.widget_isha", "") ?: "",
                    locationVal = prefs.getString("flutter.widget_location", "") ?: ""
                )
            }
        }
    }
}