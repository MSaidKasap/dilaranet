package com.dilara.social

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import java.util.Calendar
import java.util.Timer
import java.util.TimerTask

class PrayerNotificationService : Service() {

    private val CHANNEL_ID = "prayer_ongoing_channel_native"
    private val NOTIFICATION_ID = 2001
    private var timer: Timer? = null

    companion object {
        var fajr = ""
        var sunrise = ""
        var dhuhr = ""
        var asr = ""
        var maghrib = ""
        var isha = ""
        var location = ""

        // 45dk uyarısı aynı vakit için tekrar tekrar kurulmasın diye
        private var lastScheduledExitMinute = -1

        fun startOrUpdate(
            context: Context,
            fajrVal: String, sunriseVal: String, dhuhrVal: String,
            asrVal: String, maghribVal: String, ishaVal: String,
            locationVal: String
        ) {
            fajr = fajrVal; sunrise = sunriseVal; dhuhr = dhuhrVal
            asr = asrVal; maghrib = maghribVal; isha = ishaVal
            location = locationVal

            val intent = Intent(context, PrayerNotificationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                context.startForegroundService(intent)
            else
                context.startService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, PrayerNotificationService::class.java))
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        scheduleHeadsUpAlert()
        startTimer()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }

    private fun startTimer() {
        timer?.cancel()
        timer = Timer()
        // Sayaç (Chronometer) sistem tarafından otomatik akıyor, biz sadece
        // progress bar / olası vakit değişimini yakalamak için 60sn'de bir
        // bildirimi tazeliyoruz (içerik aynıysa görsel bir kesinti olmaz).
        timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification())
                scheduleHeadsUpAlert()
            }
        }, 60_000L, 60_000L)
    }

    private fun buildNotification(): Notification {
        val (periodStart, periodEnd, nextName) = getCurrentPeriod()

        val now = Calendar.getInstance()
        val curMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        var elapsed = curMinute - periodStart
        if (elapsed < 0) elapsed += 1440
        var total = periodEnd - periodStart
        if (total <= 0) total += 1440
        val progressPermille = ((elapsed.toFloat() / total.toFloat()) * 1000).toInt().coerceIn(0, 1000)

        val remainingMillis = remainingMillisTo(periodEnd)
        val hours = (remainingMillis / 3_600_000L).toInt()
        val minuteSecondMillis = remainingMillis % 3_600_000L
        val base = SystemClock.elapsedRealtime() + minuteSecondMillis
        val hourText = hours.toString().padStart(2, '0')
        val title = "${nextName}"

        // Büyük (genişletilmiş) görünüm
        val bigViews = RemoteViews(packageName, R.layout.notification_prayer_live)
        bigViews.setTextViewText(R.id.tv_title, title)
        bigViews.setTextViewText(R.id.tv_hours, hourText)
        bigViews.setChronometer(R.id.chronometer_countdown, base, null, true)
        bigViews.setProgressBar(R.id.progress_prayer, 1000, progressPermille, false)

        // Küçük (kapalı) görünüm
        val compactViews = RemoteViews(packageName, R.layout.notification_prayer_live_compact)
        compactViews.setTextViewText(R.id.tv_title_compact, title)
        compactViews.setTextViewText(R.id.tv_hours_compact, hourText)
        compactViews.setChronometer(R.id.chronometer_countdown_compact, base, null, true)
        compactViews.setProgressBar(R.id.progress_prayer_compact, 1000, progressPermille, false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            bigViews.setChronometerCountDown(R.id.chronometer_countdown, true)
            compactViews.setChronometerCountDown(R.id.chronometer_countdown_compact, true)
        }

        val openIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val deleteIntent = PendingIntent.getBroadcast(
            this, 99,
            Intent(this, NotificationDismissReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(compactViews)
            .setCustomBigContentView(bigViews)
            .setContentIntent(openIntent)
            .setDeleteIntent(deleteIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    /** Şu an içinde bulunduğumuz vakit aralığının (başlangıç, bitiş, bitişteki vakit adı) bilgisini döner. */
    private fun getCurrentPeriod(): Triple<Int, Int, String> {
        val list = listOf(
            "İmsak" to fajr, "Güneş" to sunrise, "Öğle" to dhuhr,
            "İkindi" to asr, "Akşam" to maghrib, "Yatsı" to isha
        )
        val minutes = list.map { (name, t) ->
            val parts = t.split(":")
            val h = parts.getOrNull(0)?.trim()?.toIntOrNull() ?: 0
            val m = parts.getOrNull(1)?.trim()?.toIntOrNull() ?: 0
            name to (h * 60 + m)
        }

        val now = Calendar.getInstance()
        val cur = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

        for (i in minutes.indices) {
            if (minutes[i].second > cur) {
                val prevIndex = if (i == 0) minutes.size - 1 else i - 1
                return Triple(minutes[prevIndex].second, minutes[i].second, minutes[i].first)
            }
        }
        // Şu an Yatsı'dan sonra, İmsak'a kadar
        return Triple(minutes.last().second, minutes.first().second, minutes.first().first)
    }

    private fun remainingMillisTo(targetMinuteOfDay: Int): Long {
        val now = Calendar.getInstance()
        val cur = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        var diffMinutes = targetMinuteOfDay - cur
        if (diffMinutes < 0) diffMinutes += 1440
        // dakika hassasiyetinden kaynaklanan saniye kaymasını telafi et
        val secondsIntoMinute = now.get(Calendar.SECOND)
        return (diffMinutes * 60_000L) - (secondsIntoMinute * 1000L)
    }

    /** Mevcut vaktin çıkmasına 45 dk kala tek seferlik sesli bildirim kurar. */
    private fun scheduleHeadsUpAlert() {
        val (_, periodEnd, exitingName) = getCurrentPeriod()
        if (lastScheduledExitMinute == periodEnd) return // bu vakit için zaten kuruldu

        val remainingMillis = remainingMillisTo(periodEnd)
        val alertOffsetMillis = 45 * 60_000L
        val triggerInMillis = remainingMillis - alertOffsetMillis

        if (triggerInMillis <= 0) return // 45dk'dan az kaldıysa (ör. servis geç başladı), atla

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, PrayerAlertReceiver::class.java).apply {
            putExtra(PrayerAlertReceiver.EXTRA_PRAYER_NAME, exitingName)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, periodEnd, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val triggerAt = SystemClock.elapsedRealtime() + triggerInMillis
        val canScheduleExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager.canScheduleExactAlarms()

        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && canScheduleExact -> {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    // Exact alarm izni yok (kullanıcı henüz vermemiş) -> sistemin
                    // kendi takdirine bırakılan, izin gerektirmeyen alarma düş.
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent
                    )
                }
                else -> {
                    alarmManager.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
                }
            }
            lastScheduledExitMinute = periodEnd
        } catch (e: SecurityException) {
            // Beklenmedik izin reddi - servisi çökertme, sadece alarmı atla
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "Namaz Vakitleri",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Sürekli namaz vakti bildirimi"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(ch)
        }
    }
}