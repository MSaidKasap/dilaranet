package com.dilara.social

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

/**
 * Her namaz vaktinde tüm widget'ları günceller.
 * updatePeriodMillis Android tarafından 30 dk'da bir tetiklenir ve vakit geçişini yakalamaz.
 * Bu sınıf AlarmManager ile tam vakitte exact alarm kurar.
 */
object PrayerAlarmScheduler {

    const val ACTION_PRAYER_TIME_TICK = "com.dilara.social.PRAYER_TIME_TICK"

    /**
     * Bir sonraki namaz vaktine exact alarm kurar.
     * Her widget güncellendiğinde çağrılır.
     */
    fun scheduleNext(context: Context, prayers: List<Pair<String, String>>) {
        val now = Calendar.getInstance()
        val nowSec = now.get(Calendar.HOUR_OF_DAY) * 3600 +
                     now.get(Calendar.MINUTE) * 60 +
                     now.get(Calendar.SECOND)

        // Sıradaki vaktin zamanını bul
        var targetMillis: Long? = null
        for ((_, time) in prayers) {
            val parts = time.split(":").mapNotNull { it.toIntOrNull() }
            if (parts.size < 2) continue
            val sec = parts[0] * 3600 + parts[1] * 60
            if (sec > nowSec) {
                val target = now.clone() as Calendar
                target.set(Calendar.HOUR_OF_DAY, parts[0])
                target.set(Calendar.MINUTE, parts[1])
                target.set(Calendar.SECOND, 0)
                target.set(Calendar.MILLISECOND, 0)
                targetMillis = target.timeInMillis
                break
            }
        }

        // Tüm vakitler geçtiyse ertesi gün ilk vakti hedefle
        if (targetMillis == null) {
            val first = prayers.firstOrNull()?.second ?: return
            val parts = first.split(":").mapNotNull { it.toIntOrNull() }
            if (parts.size < 2) return
            val target = now.clone() as Calendar
            target.add(Calendar.DAY_OF_MONTH, 1)
            target.set(Calendar.HOUR_OF_DAY, parts[0])
            target.set(Calendar.MINUTE, parts[1])
            target.set(Calendar.SECOND, 0)
            target.set(Calendar.MILLISECOND, 0)
            targetMillis = target.timeInMillis
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(ACTION_PRAYER_TIME_TICK).apply {
            setPackage(context.packageName)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Exact alarm — Android 12+ için izin gerekir (Manifest'te USE_EXACT_ALARM zaten var ✅)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    targetMillis!!,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    targetMillis!!,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            // USE_EXACT_ALARM izni verilmemişse fallback: 1 dakikada bir kontrol
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + 60_000,
                pendingIntent
            )
        }
    }

    /** Tüm alarmları iptal eder (widget kaldırıldığında çağır) */
    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(ACTION_PRAYER_TIME_TICK).apply {
            setPackage(context.packageName)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
