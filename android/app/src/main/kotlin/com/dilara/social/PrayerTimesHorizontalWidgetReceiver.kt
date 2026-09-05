package com.dilara.social

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class PrayerTimesHorizontalWidgetReceiver : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val vakitTimeIds = listOf(
            R.id.widget_fajr_time,
            R.id.widget_sunrise_time,
            R.id.widget_dhuhr_time,
            R.id.widget_asr_time,
            R.id.widget_maghrib_time,
            R.id.widget_isha_time
        )
        // Vakit saatlerini SharedPreferences'tan çek
        val prefs = context.getSharedPreferences("HomeWidget", Context.MODE_PRIVATE)
        val vakitTimes = listOf(
            prefs.getString("widget_fajr", "--:--") ?: "--:--",
            prefs.getString("widget_sunrise", "--:--") ?: "--:--",
            prefs.getString("widget_dhuhr", "--:--") ?: "--:--",
            prefs.getString("widget_asr", "--:--") ?: "--:--",
            prefs.getString("widget_maghrib", "--:--") ?: "--:--",
            prefs.getString("widget_isha", "--:--") ?: "--:--"
        )
        val currentVakitIndex = getCurrentVakitIndex(vakitTimes)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.dilara_widget_horizontal)
            // Tüm saatleri şeffaf yap ve saatleri güncelle
            for (i in vakitTimeIds.indices) {
                views.setInt(vakitTimeIds[i], "setBackgroundResource", android.R.color.transparent)
                views.setTextViewText(vakitTimeIds[i], vakitTimes[i])
            }
            // Sadece güncel vakit saatine sarı arka plan ver
            if (currentVakitIndex in vakitTimeIds.indices) {
                views.setInt(vakitTimeIds[currentVakitIndex], "setBackgroundResource", R.drawable.bg_current_prayer_transparent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getCurrentVakitIndex(times: List<String>): Int {
        val now = java.util.Calendar.getInstance()
        val nowSeconds = now.get(java.util.Calendar.HOUR_OF_DAY) * 3600 +
            now.get(java.util.Calendar.MINUTE) * 60 +
            now.get(java.util.Calendar.SECOND)
        for ((idx, time) in times.withIndex()) {
            val parts = time.split(":").mapNotNull { it.toIntOrNull() }
            if (parts.size < 2) continue
            val seconds = parts[0] * 3600 + parts[1] * 60
            if (seconds > nowSeconds) {
                return idx
            }
        }
        // Eğer gün bitti ise ilk vakte dön
        return 0
    }
}
