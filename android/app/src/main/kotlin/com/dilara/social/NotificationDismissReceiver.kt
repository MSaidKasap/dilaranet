package com.dilara.social

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Bildirim kapatıldı ama servis hâlâ ayakta - bildirimi geri getir.
        if (PrayerNotificationService.fajr.isNotEmpty()) {
            PrayerNotificationService.startOrUpdate(
                context = context,
                fajrVal = PrayerNotificationService.fajr,
                sunriseVal = PrayerNotificationService.sunrise,
                dhuhrVal = PrayerNotificationService.dhuhr,
                asrVal = PrayerNotificationService.asr,
                maghribVal = PrayerNotificationService.maghrib,
                ishaVal = PrayerNotificationService.isha,
                locationVal = PrayerNotificationService.location
            )
        }
    }
}