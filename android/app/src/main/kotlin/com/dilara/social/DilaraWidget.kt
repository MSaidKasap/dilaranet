package com.dilara.social

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.util.Calendar

data class PrayerData(
    val fajr: String = "--:--",
    val sunrise: String = "--:--",
    val dhuhr: String = "--:--",
    val asr: String = "--:--",
    val maghrib: String = "--:--",
    val isha: String = "--:--",
    val location: String = "Konum yok",
    val date: String = ""
) {
    companion object {
        fun load(context: Context): PrayerData {
            val prefs: SharedPreferences = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            return PrayerData(
                fajr     = prefs.getString("flutter.widget_fajr",     "--:--") ?: "--:--",
                sunrise  = prefs.getString("flutter.widget_sunrise",  "--:--") ?: "--:--",
                dhuhr    = prefs.getString("flutter.widget_dhuhr",    "--:--") ?: "--:--",
                asr      = prefs.getString("flutter.widget_asr",      "--:--") ?: "--:--",
                maghrib  = prefs.getString("flutter.widget_maghrib",  "--:--") ?: "--:--",
                isha     = prefs.getString("flutter.widget_isha",     "--:--") ?: "--:--",
                location = prefs.getString("flutter.widget_location", "Konum yok") ?: "Konum yok",
                date     = prefs.getString("flutter.widget_date",     "") ?: ""
            )
        }
    }

    data class NextPrayer(val name: String, val time: String, val remaining: String)

    fun nextPrayer(): NextPrayer {
        val cal = Calendar.getInstance()
        val now = cal.get(Calendar.HOUR_OF_DAY) * 3600 +
                cal.get(Calendar.MINUTE) * 60 +
                cal.get(Calendar.SECOND)

        val list = listOf(
            "İmsak" to fajr, "Güneş" to sunrise, "Öğle" to dhuhr,
            "İkindi" to asr, "Akşam" to maghrib, "Yatsı" to isha
        )
        for ((name, time) in list) {
            val p = time.split(":").mapNotNull { it.toIntOrNull() }
            if (p.size < 2) continue
            val ps = p[0] * 3600 + p[1] * 60
            if (ps > now) {
                val d = ps - now
                val remaining = if (d / 3600 > 0)
                    String.format("%02d:%02d:%02d", d/3600, (d%3600)/60, d%60)
                else
                    String.format("%02d:%02d", (d%3600)/60, d%60)
                return NextPrayer(name, time, remaining)
            }
        }
        val fp = fajr.split(":").mapNotNull { it.toIntOrNull() }
        if (fp.size >= 2) {
            val d = 86400 - now + fp[0]*3600 + fp[1]*60
            return NextPrayer("İmsak", fajr, String.format("%02d:%02d:%02d", d/3600, (d%3600)/60, d%60))
        }
        return NextPrayer("İmsak", fajr, "--:--")
    }
}

class PrayerTimesWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PrayerTimesWidget()
}

class PrayerTimesWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = PrayerData.load(context)
        provideContent {
            WidgetContent(data)
        }
    }
}

@Composable
fun WidgetContent(data: PrayerData) {
    val next = data.nextPrayer()
    val gold = ColorProvider(Color(0xFFFFD700))
    val white = ColorProvider(Color.White)
    val dim = ColorProvider(Color(0xCCFFFFFF))
    val bg = ColorProvider(Color(0xFF1a1a2e))

    Box(modifier = GlanceModifier.fillMaxSize().background(bg).padding(0.dp)) {
        Row(modifier = GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.CenterVertically) {
            Column(
                modifier = GlanceModifier.defaultWeight().fillMaxHeight().padding(10.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = data.location.split(",").firstOrNull() ?: data.location,
                    style = TextStyle(color = dim, fontSize = 10.sp), maxLines = 1)
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(text = "Sıradaki Namaz", style = TextStyle(color = ColorProvider(Color(0x99FFFFFF)), fontSize = 9.sp))
                Spacer(modifier = GlanceModifier.height(2.dp))
                Text(text = next.name, style = TextStyle(color = gold, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                Text(text = next.time, style = TextStyle(color = white, fontSize = 24.sp, fontWeight = FontWeight.Bold))
                Spacer(modifier = GlanceModifier.height(4.dp))
                Box(modifier = GlanceModifier.background(ColorProvider(Color(0x22FFFFFF))).padding(horizontal = 8.dp, vertical = 3.dp),
                    contentAlignment = Alignment.Center) {
                    Text(text = "⏱ ${next.remaining}", style = TextStyle(color = gold, fontSize = 11.sp, fontWeight = FontWeight.Bold))
                }
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(text = data.date, style = TextStyle(color = ColorProvider(Color(0x66FFFFFF)), fontSize = 9.sp))
            }

            Box(modifier = GlanceModifier.width(1.dp).fillMaxHeight().padding(vertical = 12.dp).background(ColorProvider(Color(0x33FFFFFF)))) {}

            Column(
                modifier = GlanceModifier.defaultWeight().fillMaxHeight().padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                PrayerRow("İmsak",  data.fajr,    next.name == "İmsak",  gold, white, dim)
                PrayerRow("Güneş",  data.sunrise, next.name == "Güneş",  gold, white, dim)
                PrayerRow("Öğle",   data.dhuhr,   next.name == "Öğle",   gold, white, dim)
                PrayerRow("İkindi", data.asr,     next.name == "İkindi", gold, white, dim)
                PrayerRow("Akşam",  data.maghrib, next.name == "Akşam",  gold, white, dim)
                PrayerRow("Yatsı",  data.isha,    next.name == "Yatsı",  gold, white, dim)
            }
        }
    }
}

@Composable
fun PrayerRow(name: String, time: String, isNext: Boolean, gold: ColorProvider, white: ColorProvider, dim: ColorProvider) {
    val bg = if (isNext) ColorProvider(Color(0x22FFFFFF)) else ColorProvider(Color.Transparent)
    Box(modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp).background(bg)) {
        Row(modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Text(text = name, style = TextStyle(
                color = if (isNext) gold else dim, fontSize = 11.sp,
                fontWeight = if (isNext) FontWeight.Bold else FontWeight.Normal),
                modifier = GlanceModifier.defaultWeight())
            Text(text = time, style = TextStyle(
                color = if (isNext) gold else white, fontSize = 11.sp,
                fontWeight = if (isNext) FontWeight.Bold else FontWeight.Normal))
        }
    }
}