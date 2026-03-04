package com.dilara.social

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PrayerTimesHorizontalWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidget", Context.MODE_PRIVATE)
        val fajr    = prefs.getString("widget_fajr",    "--:--") ?: "--:--"
        val sunrise = prefs.getString("widget_sunrise", "--:--") ?: "--:--"
        val dhuhr   = prefs.getString("widget_dhuhr",   "--:--") ?: "--:--"
        val asr     = prefs.getString("widget_asr",     "--:--") ?: "--:--"
        val maghrib = prefs.getString("widget_maghrib", "--:--") ?: "--:--"
        val isha    = prefs.getString("widget_isha",    "--:--") ?: "--:--"

        val prayers = listOf(
            "İmsak"  to fajr,
            "Güneş"  to sunrise,
            "Öğle"   to dhuhr,
            "İkindi" to asr,
            "Akşam"  to maghrib,
            "Yatsı"  to isha
        )

        val currentIdx = PrayerTimesWidgetReceiver.computeCurrentPrayerIndex(prayers)

        val labelIds = listOf(
            R.id.widget_fajr_label, R.id.widget_sunrise_label, R.id.widget_dhuhr_label,
            R.id.widget_asr_label, R.id.widget_maghrib_label, R.id.widget_isha_label
        )
        val timeIds = listOf(
            R.id.widget_fajr_time, R.id.widget_sunrise_time, R.id.widget_dhuhr_time,
            R.id.widget_asr_time, R.id.widget_maghrib_time, R.id.widget_isha_time
        )
        val times = listOf(fajr, sunrise, dhuhr, asr, maghrib, isha)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.dilara_widget_horizontal)

            for (i in labelIds.indices) {
                views.setTextViewText(timeIds[i], times[i])
                if (i == currentIdx) {
                    views.setTextColor(labelIds[i], 0xFFFFD700.toInt())
                    views.setTextColor(timeIds[i],  0xFFFFD700.toInt())
                } else {
                    views.setTextColor(labelIds[i], 0x80FFFFFF.toInt())
                    views.setTextColor(timeIds[i],  0xCCFFFFFF.toInt())
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        PrayerAlarmScheduler.scheduleNext(context, prayers)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == PrayerAlarmScheduler.ACTION_PRAYER_TIME_TICK) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesHorizontalWidgetReceiver::class.java))
            onUpdate(context, manager, ids)
        }
    }
}
