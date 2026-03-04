package com.dilara.social

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.util.Calendar

class PrayerTimesWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidget", Context.MODE_PRIVATE)
        val location = prefs.getString("widget_location", "Konum") ?: "Konum"
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

        val currentIdx = computeCurrentPrayerIndex(prayers)
        val nextIdx   = (currentIdx + 1) % prayers.size
        val nextName  = prayers[nextIdx].first
        val nextTime  = prayers[nextIdx].second
        val remaining = calculateRemaining(nextTime)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.dilara_widget)

            views.setTextViewText(R.id.widget_location,         location)
            views.setTextViewText(R.id.widget_next_label,       "SIRADAKİ")
            views.setTextViewText(R.id.widget_next_prayer_name, nextName)
            views.setTextViewText(R.id.widget_next_prayer_time, nextTime)
            views.setTextViewText(R.id.widget_remaining_time,   remaining)
            views.setTextViewText(R.id.widget_sunset_label,     "Akşam")
            views.setTextViewText(R.id.widget_sunset_time,      maghrib)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        PrayerAlarmScheduler.scheduleNext(context, prayers)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == PrayerAlarmScheduler.ACTION_PRAYER_TIME_TICK) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidgetReceiver::class.java))
            onUpdate(context, manager, ids)
        }
    }

    companion object {
        fun computeCurrentPrayerIndex(times: List<Pair<String, String>>): Int {
            val now = Calendar.getInstance()
            val nowSec = now.get(Calendar.HOUR_OF_DAY) * 3600 +
                         now.get(Calendar.MINUTE) * 60 +
                         now.get(Calendar.SECOND)
            var lastPassedIdx = times.size - 1
            for ((idx, pair) in times.withIndex()) {
                val parts = pair.second.split(":").mapNotNull { it.toIntOrNull() }
                if (parts.size < 2) continue
                val sec = parts[0] * 3600 + parts[1] * 60
                if (sec <= nowSec) lastPassedIdx = idx else break
            }
            return lastPassedIdx
        }

        fun calculateRemaining(time: String): String {
            val now = Calendar.getInstance()
            val parts = time.split(":").mapNotNull { it.toIntOrNull() }
            if (parts.size < 2) return "--:--"
            val target = now.clone() as Calendar
            target.set(Calendar.HOUR_OF_DAY, parts[0])
            target.set(Calendar.MINUTE, parts[1])
            target.set(Calendar.SECOND, 0)
            if (target.before(now)) target.add(Calendar.DAY_OF_MONTH, 1)
            val diff = (target.timeInMillis - now.timeInMillis) / 1000
            return String.format("%02d s %02d dk", diff / 3600, (diff % 3600) / 60)
        }
    }
}
