package com.dilara.social

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.dilara.social.R
import java.util.Calendar

class PrayerTimesWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidget", Context.MODE_PRIVATE)
        val location = prefs.getString("widget_location", "Konum") ?: "Konum"
        val fajr = prefs.getString("widget_fajr", "--:--") ?: "--:--"
        val sunrise = prefs.getString("widget_sunrise", "--:--") ?: "--:--"
        val dhuhr = prefs.getString("widget_dhuhr", "--:--") ?: "--:--"
        val asr = prefs.getString("widget_asr", "--:--") ?: "--:--"
        val maghrib = prefs.getString("widget_maghrib", "--:--") ?: "--:--"
        val isha = prefs.getString("widget_isha", "--:--") ?: "--:--"
        val date = prefs.getString("widget_date", "--.--.----") ?: "--.--.----"

        val prayers = listOf(
            "İmsak" to fajr,
            "Güneş" to sunrise,
            "Öğle" to dhuhr,
            "İkindi" to asr,
            "Akşam" to maghrib,
            "Yatsı" to isha
        )

        val (nextName, nextTime, nextIdx) = computeNextPrayer(prayers)
        val remaining = calculateRemaining(nextTime)
        val next2Idx = (nextIdx + 1) % prayers.size
        val next2Name = prayers[next2Idx].first
        val next2Time = prayers[next2Idx].second

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.dilara_widget)
            views.setTextViewText(R.id.widget_location, location)
            views.setTextViewText(R.id.widget_next_label, "SIRADAKİ")
            views.setTextViewText(R.id.widget_next_prayer_name, nextName)
            views.setTextViewText(R.id.widget_next_prayer_time, nextTime)
            views.setTextViewText(R.id.widget_remaining_time, remaining)
            views.setTextViewText(R.id.widget_next2_label, next2Name)
            views.setTextViewText(R.id.widget_next2_time, next2Time)
            // Kırmızı işaretli alana: gün batımı ikonu, Akşam ve saat
            views.setTextViewText(R.id.widget_sunset_label, "Akşam")
            views.setTextViewText(R.id.widget_sunset_time, maghrib)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun computeNextPrayer(times: List<Pair<String, String>>): Triple<String, String, Int> {
        val now = Calendar.getInstance()
        val nowSeconds = now.get(Calendar.HOUR_OF_DAY) * 3600 +
            now.get(Calendar.MINUTE) * 60 +
            now.get(Calendar.SECOND)
        for ((idx, pair) in times.withIndex()) {
            val (name, time) = pair
            val parts = time.split(":").mapNotNull { it.toIntOrNull() }
            if (parts.size < 2) continue
            val seconds = parts[0] * 3600 + parts[1] * 60
            if (seconds > nowSeconds) {
                return Triple(name, time, idx)
            }
        }
        // If all passed, roll to next day İmsak
        return Triple(times.first().first, times.first().second, 0)
    }

    private fun calculateRemaining(time: String): String {
        val now = Calendar.getInstance()
        val parts = time.split(":").mapNotNull { it.toIntOrNull() }
        if (parts.size < 2) return "--:--"
        val target = now.clone() as Calendar
        target.set(Calendar.HOUR_OF_DAY, parts[0])
        target.set(Calendar.MINUTE, parts[1])
        target.set(Calendar.SECOND, 0)
        if (target.before(now)) {
            target.add(Calendar.DAY_OF_MONTH, 1)
        }
        val diff = (target.timeInMillis - now.timeInMillis) / 1000
        val hours = diff / 3600
        val minutes = (diff % 3600) / 60
        return String.format("%02d s %02d dk", hours, minutes)
    }
}