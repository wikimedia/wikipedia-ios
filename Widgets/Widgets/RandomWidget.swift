import WidgetKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

// MARK: - Color Set

private enum RandomWidgetColorSet {
    case pink
    case purple
    case blue

    var primary: Color {
        switch self {
        case .pink:   return Color(red: 245/255, green: 235/255, blue: 242/255)
        case .purple: return Color(red: 230/255, green: 224/255, blue: 240/255)
        case .blue:   return Color(red: 182/255, green: 212/255, blue: 251/255)
        }
    }

    var secondary: Color {
        switch self {
        case .pink:   return Color(red: 155/255, green:  82/255, blue: 127/255)
        case .purple: return Color(red:  83/255, green:  79/255, blue: 163/255)
        case .blue:   return Color(red:  48/255, green:  86/255, blue: 169/255)
        }
    }

    var tertiary: Color? {
        switch self {
        case .pink:   return Color(red: 198/255, green: 144/255, blue: 180/255)
        case .purple: return Color(red: 197/255, green: 185/255, blue: 221/255)
        case .blue:   return nil
        }
    }
}

// MARK: - Entry

struct RandomWidgetEntry: TimelineEntry {
    let date: Date
}

// MARK: - Provider

struct RandomWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> RandomWidgetEntry {
        RandomWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RandomWidgetEntry) -> Void) {
        completion(RandomWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RandomWidgetEntry>) -> Void) {
        WMFDataEnvironment.current.testKitchenClient = TestKitchenAdapter.shared.client
        Task {
            let nextMidnight = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            )
            let entry = RandomWidgetEntry(date: Date())
            let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                EventPlatformClient.shared.flushStoredEvents {
                    continuation.resume()
                }
            }
            completion(timeline)
        }
    }
}

// MARK: - Display Sets

private extension WMFRandomWidgetViewModel.DisplaySet {

    static func dailyIndex(optionsCount: Int) -> Int {
        guard optionsCount > 0,
              let userDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia") else {
            return 0
        }
        let today = Calendar.current.startOfDay(for: Date())
        let indexKey = WMFUserDefaultsKey.randomWidgetDailyIndex.rawValue
        let dateKey = WMFUserDefaultsKey.randomWidgetDailyDate.rawValue
        let lastDate = userDefaults.object(forKey: dateKey) as? Date ?? .distantPast
        if Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return userDefaults.integer(forKey: indexKey)
        }
        let newIndex = Int.random(in: 0..<optionsCount)
        userDefaults.set(newIndex, forKey: indexKey)
        userDefaults.set(today, forKey: dateKey)
        return newIndex
    }

    static func make(family: WidgetFamily) -> WMFRandomWidgetViewModel.DisplaySet {
        let icon = WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1)
        let button1Title = family == .systemSmall ? CommonStrings.randomButton : CommonStrings.randomArticleButton
        let button1Icon = WMFSFSymbolIcon.for(symbol: .diceFill, font: .semiboldSubheadline)
        let button1URL = URL(string: "wikipedia://random?source=widget_random_article")

        func makeSet(_ colorSet: RandomWidgetColorSet, image: String) -> WMFRandomWidgetViewModel.DisplaySet {
            WMFRandomWidgetViewModel.DisplaySet(
                color: colorSet.primary,
                color2: colorSet.secondary,
                color3: colorSet.tertiary,
                image: image,
                title: "",
                subtitle: "",
                button1Title: button1Title,
                button1URL: button1URL,
                button1Icon: button1Icon,
                icon: icon
            )
        }

        let displaySets = [
            makeSet(.pink,   image: "phoneGlobe"),
            makeSet(.purple, image: Int.random(in: 1...2) == 1 ? "musicGlobe1" : "musicGlobe2"),
            makeSet(.blue,   image: "spaceGlobe")
        ]

        return displaySets[dailyIndex(optionsCount: displaySets.count)]
    }
}

// MARK: - Entry View

struct RandomWidgetEntryView: View {
    let entry: RandomWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let displaySet = WMFRandomWidgetViewModel.DisplaySet.make(family: family)
        return WMFRandomWidgetView(
            viewModel: WMFRandomWidgetViewModel(
                localizedStrings: WMFRandomWidgetViewModel.LocalizedStrings(title: displaySet.title),
                displaySet: displaySet
            )
        )
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "wikipedia://random?source=widget_random_article"))
    }
}

// MARK: - Widget

struct RandomWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.randomWidget.identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RandomWidgetProvider()) { entry in
            RandomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(CommonStrings.randomArticleButton)
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
