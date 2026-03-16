import WidgetKit
import SwiftUI
import WMF
import WMFComponents
import WMFData

// MARK: - Entry

struct ReadingChallengeEntry: TimelineEntry {
    let date: Date
    let state: ReadingChallengeState
}

// MARK: - Provider

struct ReadingChallengeProvider: TimelineProvider {

    func placeholder(in context: Context) -> ReadingChallengeEntry {
        ReadingChallengeEntry(date: Date(), state: .notEnrolled)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingChallengeEntry) -> Void) {
        completion(ReadingChallengeEntry(date: Date(), state: .notEnrolled))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingChallengeEntry>) -> Void) {

        Task {
            let state = await resolvedState()

            // Refresh at the next midnight so the "not yet read today" reset fires.
            let nextMidnight = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            )

            let entry = ReadingChallengeEntry(date: Date(), state: state)
            let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
            completion(timeline)
        }
    }

    private func resolvedState() async -> ReadingChallengeState {
        do {
            // Set up the shared app group container URL so WMFCoreDataStore can locate the database
            let appContainerURL = FileManager.default.wmf_containerURL()
            WMFDataEnvironment.current.appContainerURL = appContainerURL

            let coreDataStore = try await WMFCoreDataStore(appContainerURL: appContainerURL)
            let controller = try WMFPageViewsDataController(coreDataStore: coreDataStore)
            let isEnrolled = true // UserDefaults(suiteName: "group.org.wikimedia.wikipedia")?.bool(forKey: "readingChallengeEnrolled") ?? false
            return try await controller.fetchReadingChallengeState(isEnrolled: isEnrolled)
        } catch {
            return .notEnrolled
        }
    }
}
// MARK: - Display Sets

private extension WMFReadingChallengeWidgetViewModel.DisplaySet {

    static func streakSet(streak: Int) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: Color(red: 245/255, green: 235/255, blue: 242/255),
            color2: Color(red: 155/255, green: 82/255, blue: 127/255),
            color3: Color(red: 198/255, green: 144/255, blue: 180/255),
            image: "globephone",
            title: "\(streak) day\(streak == 1 ? "" : "s")",
            subtitle: "25-day reading challenge",
            icon: WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1)
        )
    }

    static func streakNotYetReadSet(streak: Int, showButtons: Bool) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: Color(red: 255/255, green: 234/255, blue: 212/255),
            color2: Color(red: 169/255, green: 82/255, blue: 38/255),
            color3: nil,
            image: "sleepyglobe",
            title: "\(streak) day\(streak == 1 ? "" : "s")",
            subtitle: "Don't let today drift by, save your streak.",
            button1Title: showButtons ? "Search" : nil,
            button2Title: showButtons ? "Random" : nil,
            button1URL: showButtons ? URL(string: "wikipedia://search") : nil,
            button2URL: showButtons ? URL(string: "wikipedia://random") : nil,
            button1Icon: showButtons ? WMFSFSymbolIcon.for(symbol: .magnifyingGlass, font: .semiboldSubheadline) : nil,
            button2Icon: showButtons ? WMFSFSymbolIcon.for(symbol: .diceFill, font: .semiboldSubheadline) : nil
        )
    }

    static let completedSet = WMFReadingChallengeWidgetViewModel.DisplaySet(
        color: Color(red: 182/255, green: 212/255, blue: 251/255),
        color2: Color(red: 10/255, green: 36/255, blue: 77/255),
        image: "globe1",
        title: "25 of 25",
        subtitle: nil,
        button1Title: "Collect prize",
        button1URL: URL(string: "wikipedia://activity")
    )

    static func incompleteSet(streak: Int) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: .red,
            color2: .red,
            image: "globe1",
            title: "\(streak) day\(streak == 1 ? "" : "s")"
        )
    }

    static let noStreakSet = WMFReadingChallengeWidgetViewModel.DisplaySet(
        color: .gray,
        color2: .gray,
        image: "globe1",
        title: ""
    )

    static let notEnrolledSet = WMFReadingChallengeWidgetViewModel.DisplaySet(
        color: .blue,
        color2: .gray,
        image: "globe1",
        title: "not enrolled",
        button1Title: "Search",
        button2Title: "Random",
        button1URL: URL(string: "wikipedia://search"),
        button2URL: URL(string: "wikipedia://random"),
        button1Icon: nil,
        button2Icon: nil
    )

    static func make(
        for state: ReadingChallengeState,
        family: WidgetFamily
    ) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        switch state {
        case .streakOngoingRead(let streak):
            return streakSet(streak: streak)
        case .streakOngoingNotYetRead(let streak):
            return streakNotYetReadSet(streak: streak, showButtons: family == .systemMedium)
        case .challengeCompleted:
            return completedSet
        case .challengeConcludedIncomplete(let streak):
            return incompleteSet(streak: streak)
        case .challengeConcludedNoStreak:
            return noStreakSet
        case .notEnrolled, .notLiveYet, .challengeRemoved, .enrolledNotStarted:
            return notEnrolledSet
        }
    }
}

// MARK: - Entry View

struct ReadingChallengeEntryView: View {
    let entry: ReadingChallengeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        WMFReadingChallengeWidgetView(
            viewModel: WMFReadingChallengeWidgetViewModel(
                localizedStrings: WMFReadingChallengeWidgetViewModel.LocalizedStrings(
                    title: titleString(for: entry.state)
                ),
                displaySet: WMFReadingChallengeWidgetViewModel.DisplaySet.make(
                    for: entry.state,
                    family: family
                ),
                state: entry.state
            )
        )
        .widgetURL(URL(string: "wikipedia://explore"))
    }

    private func titleString(for state: ReadingChallengeState) -> String {
        switch state {
        case .streakOngoingRead(let streak), .streakOngoingNotYetRead(let streak):
            return "\(streak) day\(streak == 1 ? "" : "s")"
        case .challengeCompleted:
            return "25 of 25"
        case .challengeConcludedIncomplete(let streak):
            return "\(streak) day\(streak == 1 ? "" : "s")"
        case .notEnrolled:
            return "notEnrolled"
        case .notLiveYet:
            return "notLiveYet"
        case .challengeRemoved:
            return "challengeRemoved"
        case .enrolledNotStarted:
            return "enrolledNotStarted"
        case .challengeConcludedNoStreak:
            return "challengeConcludedNoStreak"
        }
    }
}

// MARK: - Widget

struct ReadingChallengeWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.readingChallenge.identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingChallengeProvider()) { entry in
            ReadingChallengeEntryView(entry: entry)
        }
        .configurationDisplayName("Reading Challenge")
        .description("Track your reading challenge progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
