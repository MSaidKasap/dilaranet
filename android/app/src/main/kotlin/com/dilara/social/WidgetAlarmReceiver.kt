package com.dilara.social

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class WidgetAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            setupWidgetAlarm(context)
            restartPrayerService(context)
        }
    }

    private fun restartPrayerService(context: Context) {
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

    private fun setupWidgetAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val widgetReceivers = listOf(
            PrayerTimesWidgetReceiver::class.java,
            PrayerTimesBigWidgetReceiver::class.java,
            PrayerTimesHorizontalWidgetReceiver::class.java
        )
        for (receiver in widgetReceivers) {
            val intent = Intent(context, receiver)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                receiver.name.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
            )
            val calendar = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.MINUTE, 1)
            }
            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                60 * 1000L,
                pendingIntent
            )
        }
    }
}