package com.dilara.social

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * AlarmManager'dan gelen PRAYER_TIME_TICK aksiyonunu dinler.
 * Her namaz vaktinde tüm widget'ları günceller.
 */
class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != PrayerAlarmScheduler.ACTION_PRAYER_TIME_TICK) return

        val manager = AppWidgetManager.getInstance(context)

        val receivers = listOf(
            PrayerTimesWidgetReceiver::class.java,
            PrayerTimesHorizontalWidgetReceiver::class.java,
            PrayerTimesBigWidgetReceiver::class.java
        )

        for (cls in receivers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            if (ids.isNotEmpty()) {
                val updateIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    component = ComponentName(context, cls)
                }
                context.sendBroadcast(updateIntent)
            }
        }
    }
}
