package com.dilara.social  // ✅ net. değil com.

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.Build
import java.util.Calendar

class MainActivity : FlutterActivity() {
        override fun onStart() {
            super.onStart()
            setupWidgetAlarm(this)
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
                    PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
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
    private val CHANNEL = "net.dilara.social/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePrayerTimes" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            if (args == null) {
                                result.error("INVALID_ARGS", "Map bekleniyor", null)
                                return@setMethodCallHandler
                            }

                            // SharedPreferences'e kaydet (app ve widget için)
                            val prefs = getSharedPreferences(
                                "FlutterSharedPreferences",
                                Context.MODE_PRIVATE
                            )
                            with(prefs.edit()) {
                                putString("flutter.widget_fajr", args["fajr"].toString())
                                putString("flutter.widget_sunrise", args["sunrise"].toString())
                                putString("flutter.widget_dhuhr", args["dhuhr"].toString())
                                putString("flutter.widget_asr", args["asr"].toString())
                                putString("flutter.widget_maghrib", args["maghrib"].toString())
                                putString("flutter.widget_isha", args["isha"].toString())
                                putString("flutter.widget_location", args["location"].toString())
                                putString("flutter.widget_date", args["date"].toString())
                                commit() // apply() yerine commit() kullan
                            }

                            // HomeWidget için bireysel ve özet verisi kaydet
                            val homeWidgetPrefs = getSharedPreferences("HomeWidget", Context.MODE_PRIVATE)
                            with(homeWidgetPrefs.edit()) {
                                putString("widget_fajr", args["fajr"].toString())
                                putString("widget_sunrise", args["sunrise"].toString())
                                putString("widget_dhuhr", args["dhuhr"].toString())
                                putString("widget_asr", args["asr"].toString())
                                putString("widget_maghrib", args["maghrib"].toString())
                                putString("widget_isha", args["isha"].toString())
                                putString("widget_date", args["date"].toString())
                                putString("widget_location", args["location"].toString())
                                val summary = "Fajr: ${args["fajr"]}\nSunrise: ${args["sunrise"]}\nDhuhr: ${args["dhuhr"]}\nAsr: ${args["asr"]}\nMaghrib: ${args["maghrib"]}\nIsha: ${args["isha"]}\nLokasyon: ${args["location"]}\nTarih: ${args["date"]}"
                                putString("prayer_times", summary)
                                commit()
                            }

                            val manager = AppWidgetManager.getInstance(this@MainActivity)
                            val ids = manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, PrayerTimesWidgetReceiver::class.java)
                            )
                            if (ids.isNotEmpty()) {
                                val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                                    setComponent(ComponentName(this@MainActivity, PrayerTimesWidgetReceiver::class.java))
                                }
                                sendBroadcast(intent)
                            }
                            result.success("OK")
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "updateAndroidWidget" -> {
                        try {
                            val manager = AppWidgetManager.getInstance(this@MainActivity)
                            val ids = manager.getAppWidgetIds(
                                ComponentName(this@MainActivity, PrayerTimesWidgetReceiver::class.java)
                            )
                            val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                            }
                            sendBroadcast(intent)
                            result.success("OK")
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}