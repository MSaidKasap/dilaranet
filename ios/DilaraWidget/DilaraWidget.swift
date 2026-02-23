import WidgetKit
import SwiftUI

// MARK: - Prayer Data
struct PrayerData {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let location: String
    let date: String

    static func load() -> PrayerData {
        let defaults = UserDefaults(suiteName: "group.net.dilara.social") ?? UserDefaults.standard
        return PrayerData(
            fajr:     defaults.string(forKey: "flutter.widget_fajr")     ?? "--:--",
            sunrise:  defaults.string(forKey: "flutter.widget_sunrise")  ?? "--:--",
            dhuhr:    defaults.string(forKey: "flutter.widget_dhuhr")    ?? "--:--",
            asr:      defaults.string(forKey: "flutter.widget_asr")      ?? "--:--",
            maghrib:  defaults.string(forKey: "flutter.widget_maghrib")  ?? "--:--",
            isha:     defaults.string(forKey: "flutter.widget_isha")     ?? "--:--",
            location: defaults.string(forKey: "flutter.widget_location") ?? "Konum yok",
            date:     defaults.string(forKey: "flutter.widget_date")     ?? ""
        )
    }

  func nextPrayer(at now: Date = Date()) -> (name: String, time: String, remaining: String) {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: now)
    let minute = cal.component(.minute, from: now)
    let currentMinutes = hour * 60 + minute  // Saniye yok

    let prayers: [(String, String)] = [
        ("İmsak", fajr), ("Güneş", sunrise), ("Öğle", dhuhr),
        ("İkindi", asr), ("Akşam", maghrib), ("Yatsı", isha)
    ]

    for (name, time) in prayers {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { continue }
        let prayerMinutes = parts[0] * 60 + parts[1]
        if prayerMinutes > currentMinutes {
            let diff = prayerMinutes - currentMinutes
            let h = diff / 60
            let m = diff % 60
            let remaining = h > 0 ? String(format: "%02d s %02d dk", h, m) : String(format: "%02d dk", m)
            return (name, time, remaining)
        }
    }

    let fajrParts = fajr.split(separator: ":").compactMap { Int($0) }
    if fajrParts.count >= 2 {
        let nextFajrMinutes = (24 * 60) - currentMinutes + fajrParts[0] * 60 + fajrParts[1]
        let h = nextFajrMinutes / 60
        let m = nextFajrMinutes % 60
        return ("İmsak", fajr, h > 0 ? String(format: "%02d s %02d dk", h, m) : String(format: "%02d dk", m))
    }
    return ("İmsak", fajr, "--:--")
}
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let prayerData: PrayerData
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), prayerData: PrayerData(
            fajr: "05:30", sunrise: "07:10", dhuhr: "12:45",
            asr: "15:30", maghrib: "18:20", isha: "19:50",
            location: "Isparta", date: "21.02.2026"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), prayerData: PrayerData.load()))
    }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    let data = PrayerData.load()
    let now = Date()
    var entries: [SimpleEntry] = []

    for minuteOffset in 0..<60 {
        if let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) {
            entries.append(SimpleEntry(date: entryDate, prayerData: data))
        }
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
}
}

// MARK: - Arka plan rengi — köşeler dahil tam siyah
struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(
                Color(hex: "0d0d0d"),
                for: .widget
            )
        } else {
            content.background(Color(hex: "0d0d0d"))
        }
    }
}

// MARK: - Ana Widget View
struct DilaraWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .modifier(WidgetBackgroundModifier())
    }
}

// MARK: - Küçük Widget
struct SmallWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        let data = entry.prayerData
     let next = data.nextPrayer(at: entry.date)  // Date() yerine entry.date

        ZStack {
            // Tam arka plan — köşelere kadar
            Color(hex: "0d0d0d")
                .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "0d0d0d")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 4) {
                // Konum
                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "FFD700"))
                    Text(data.location.components(separatedBy: ",").first ?? data.location)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Divider().overlay(Color.white.opacity(0.2))

                Text("Sıradaki")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                Text(next.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))

                Text(next.time)
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)

                // ✅ Kalan süre
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "FFD700").opacity(0.8))
                    Text(next.remaining)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "FFD700").opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                )

                Divider().overlay(Color.white.opacity(0.2))

                HStack {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("Akşam")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(data.maghrib)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(10)
        }
    }
}

// MARK: - Orta Widget
struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        let data = entry.prayerData
        let next = data.nextPrayer()

        ZStack {
            // Tam arka plan
            Color(hex: "0d0d0d")
                .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "0d0d0d")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {

                // Sol panel
                VStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "FFD700"))
                        Text(data.location.components(separatedBy: ",").first ?? data.location)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }

                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "FFD700"))

                    Text("Sıradaki Namaz")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)

                    Text(next.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))

                    Text(next.time)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)

                    // ✅ Kalan süre
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "FFD700").opacity(0.8))
                        Text(next.remaining)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "FFD700").opacity(0.9))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                    )

                    Text(data.date)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                // Dikey ayırıcı
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 14)

                // Sağ panel
                VStack(spacing: 4) {
                    PrayerRow(icon: "moon.zzz.fill",  name: "İmsak",  time: data.fajr,    isNext: next.name == "İmsak")
                    PrayerRow(icon: "sunrise.fill",    name: "Güneş",  time: data.sunrise, isNext: next.name == "Güneş")
                    PrayerRow(icon: "sun.max.fill",    name: "Öğle",   time: data.dhuhr,   isNext: next.name == "Öğle")
                    PrayerRow(icon: "cloud.sun.fill",  name: "İkindi", time: data.asr,     isNext: next.name == "İkindi")
                    PrayerRow(icon: "sunset.fill",     name: "Akşam",  time: data.maghrib, isNext: next.name == "Akşam")
                    PrayerRow(icon: "moon.fill",       name: "Yatsı",  time: data.isha,    isNext: next.name == "Yatsı")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.trailing, 8)
            }
        }
    }
}

// MARK: - Namaz Satırı
struct PrayerRow: View {
    let icon: String
    let name: String
    let time: String
    let isNext: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(isNext ? Color(hex: "FFD700") : .white.opacity(0.4))
                .frame(width: 14)

            Text(name)
                .font(.caption2)
                .foregroundColor(isNext ? Color(hex: "FFD700") : .white.opacity(0.8))
                .frame(width: 42, alignment: .leading)

            Spacer()

            Text(time)
                .font(.system(size: 11, weight: isNext ? .bold : .regular, design: .monospaced))
                .foregroundColor(isNext ? Color(hex: "FFD700") : .white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isNext ? Color.white.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Hex Renk
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Widget Tanımı
struct DilaraWidget: Widget {
    let kind: String = "DilaraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DilaraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dilara - Namaz Vakitleri")
        .description("Günlük namaz vakitlerini gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    DilaraWidget()
} timeline: {
    SimpleEntry(date: .now, prayerData: PrayerData(
        fajr: "05:30", sunrise: "07:10", dhuhr: "12:45",
        asr: "15:30", maghrib: "18:20", isha: "19:50",
        location: "Isparta", date: "21.02.2026"
    ))
}

#Preview(as: .systemMedium) {
    DilaraWidget()
} timeline: {
    SimpleEntry(date: .now, prayerData: PrayerData(
        fajr: "05:30", sunrise: "07:10", dhuhr: "12:45",
        asr: "15:30", maghrib: "18:20", isha: "19:50",
        location: "Isparta", date: "21.02.2026"
    ))
}