package com.dilara.social

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Uygulama başlatıldığında veya cihaz yeniden başladığında alarmı tekrar kur
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            try {
                val mainActivityClass = Class.forName("com.dilara.social.MainActivity")
                val setupMethod = mainActivityClass.getDeclaredMethod("setupWidgetAlarm", Context::class.java)
                setupMethod.isAccessible = true
                setupMethod.invoke(null, context)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
