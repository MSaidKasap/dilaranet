package com.dilara.social

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

        // Uygulama açılınca servisi SharedPreferences'tan geri yükle
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val fajr = prefs.getString("flutter.widget_fajr", "") ?: ""
        if (fajr.isNotEmpty()) {
            PrayerNotificationService.startOrUpdate(
                context = this,
                fajrVal = fajr,
                sunriseVal = prefs.getString("flutter.widget_sunrise", "") ?: "",
                dhuhrVal = prefs.getString("flutter.widget_dhuhr", "") ?: "",
                asrVal = prefs.getString("flutter.widget_asr", "") ?: "",
                maghribVal = prefs.getString("flutter.widget_maghrib", "") ?: "",
                ishaVal = prefs.getString("flutter.widget_isha", "") ?: "",
                locationVal = prefs.getString("flutter.widget_location", "") ?: ""
            )
        }
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
                PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
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

                            // FlutterSharedPreferences'e kaydet
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
                                commit()
                            }

                            // HomeWidget için kaydet
                            val homeWidgetPrefs = getSharedPreferences(
                                "HomeWidget",
                                Context.MODE_PRIVATE
                            )
                            with(homeWidgetPrefs.edit()) {
                                putString("widget_fajr", args["fajr"].toString())
                                putString("widget_sunrise", args["sunrise"].toString())
                                putString("widget_dhuhr", args["dhuhr"].toString())
                                putString("widget_asr", args["asr"].toString())
                                putString("widget_maghrib", args["maghrib"].toString())
                                putString("widget_isha", args["isha"].toString())
                                putString("widget_date", args["date"].toString())
                                putString("widget_location", args["location"].toString())
                                val summary = "Fajr: ${args["fajr"]}\nSunrise: ${args["sunrise"]}\n" +
                                    "Dhuhr: ${args["dhuhr"]}\nAsr: ${args["asr"]}\n" +
                                    "Maghrib: ${args["maghrib"]}\nIsha: ${args["isha"]}\n" +
                                    "Lokasyon: ${args["location"]}\nTarih: ${args["date"]}"
                                putString("prayer_times", summary)
                                commit()
                            }

                            // Widget güncelle
                            val manager = AppWidgetManager.getInstance(this@MainActivity)
                            val ids = manager.getAppWidgetIds(
                                ComponentName(
                                    this@MainActivity,
                                    PrayerTimesWidgetReceiver::class.java
                                )
                            )
                            if (ids.isNotEmpty()) {
                                val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                                    setComponent(
                                        ComponentName(
                                            this@MainActivity,
                                            PrayerTimesWidgetReceiver::class.java
                                        )
                                    )
                                }
                                sendBroadcast(intent)
                            }

                            // Native foreground servisi başlat/güncelle
                            PrayerNotificationService.startOrUpdate(
                                context = this@MainActivity,
                                fajrVal = args["fajr"].toString(),
                                sunriseVal = args["sunrise"].toString(),
                                dhuhrVal = args["dhuhr"].toString(),
                                asrVal = args["asr"].toString(),
                                maghribVal = args["maghrib"].toString(),
                                ishaVal = args["isha"].toString(),
                                locationVal = args["location"].toString()
                            )

                            result.success("OK")
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "requestExactAlarmPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            if (!am.canScheduleExactAlarms()) {
                                startActivity(Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = android.net.Uri.parse("package:$packageName")
                                })
                            }
                        }
                        result.success("OK")
                    }
                    "getMagneticDeclination" -> {
                        // Manyetik sapma (declination): gerçek kuzey = manyetik kuzey + bu.
                        // Kıble pusulası Android'de manyetik yön aldığı için gerekli.
                        try {
                            val args = call.arguments as? Map<*, *>
                            val lat = (args?.get("lat") as? Number)?.toFloat() ?: 0f
                            val lng = (args?.get("lng") as? Number)?.toFloat() ?: 0f
                            val alt = (args?.get("alt") as? Number)?.toFloat() ?: 0f
                            val field = android.hardware.GeomagneticField(
                                lat, lng, alt, System.currentTimeMillis()
                            )
                            result.success(field.declination.toDouble())
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "updateAndroidWidget" -> {
                        try {
                            val manager = AppWidgetManager.getInstance(this@MainActivity)
                            val ids = manager.getAppWidgetIds(
                                ComponentName(
                                    this@MainActivity,
                                    PrayerTimesWidgetReceiver::class.java
                                )
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