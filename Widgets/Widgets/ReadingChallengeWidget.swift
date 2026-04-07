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
            let appContainerURL = FileManager.default.wmf_containerURL()
            WMFDataEnvironment.current.appContainerURL = appContainerURL

            let coreDataStore = try await WMFCoreDataStore(appContainerURL: appContainerURL)
            let controller = try WMFPageViewsDataController(coreDataStore: coreDataStore)
            let isEnrolled = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")?.bool(forKey: WMFUserDefaultsKey.hasEnrolledInReadingChallenge2026.rawValue) ?? false
            return try await controller.fetchReadingChallengeState(isEnrolled: isEnrolled)
        } catch {
            return .notEnrolled
        }
    }
}

// MARK: - Display Sets

private extension WMFReadingChallengeWidgetViewModel.DisplaySet {

    static func streakSet(streak: Int, colorSet: WMFTheme.ReadingChallengeColorSet = .pink) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: colorSet.primary,
            color2: colorSet.secondary,
            color3: colorSet.tertiary,
            image: "globephone",
            title: String.localizedStringWithFormat(
                WMFLocalizedString("reading-challenge-streak-days", value: "{{PLURAL:%1$d|%1$d day|%1$d days}}", comment: "Number of days in a reading challenge streak. $1 is the number of days."),
                streak
            ),
            subtitle: WMFLocalizedString("reading-challenge-subtitle", value: "25-day reading challenge", comment: "Subtitle shown on the reading challenge widget indicating the challenge length."),
            icon: WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1)
        )
    }

    static func streakNotYetReadSet(streak: Int, showButtons: Bool, colorSet: WMFTheme.ReadingChallengeColorSet = .orange) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: colorSet.primary,
            color2: colorSet.secondary,
            color3: colorSet.tertiary,
            image: "sleepyglobe",
            title: String.localizedStringWithFormat(
                WMFLocalizedString("reading-challenge-streak-days", value: "{{PLURAL:%1$d|%1$d day|%1$d days}}", comment: "Number of days in a reading challenge streak. $1 is the number of days."),
                streak
            ),
            subtitle: WMFLocalizedString("reading-challenge-not-yet-read-subtitle", value: "Don't let today drift by, save your streak.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."),
            button1Title: showButtons ? CommonStrings.searchTitle : nil,
            button2Title: showButtons ? WMFLocalizedString("reading-challenge-random-button", value: "Random", comment: "Title for the Random article button on the reading challenge widget.") : nil,
            button1URL: showButtons ? URL(string: "wikipedia://search") : nil,
            button2URL: showButtons ? URL(string: "wikipedia://random") : nil,
            button1Icon: showButtons ? WMFSFSymbolIcon.for(symbol: .magnifyingGlass, font: .semiboldSubheadline) : nil,
            button2Icon: showButtons ? WMFSFSymbolIcon.for(symbol: .diceFill, font: .semiboldSubheadline) : nil
        )
    }

    static func completedSet(family: WidgetFamily, colorSet: WMFTheme.ReadingChallengeColorSet = .blueBlack) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: colorSet.primary,
            color2: colorSet.secondary,
            color3: colorSet.tertiary,
            image: "globeParty",
            title: WMFLocalizedString("reading-challenge-completed-title", value: "You did it!", comment: "Title shown on the reading challenge widget when the user has completed the challenge."),
            subtitle: WMFLocalizedString("reading-challenge-completed-subtitle", value: "25 of 25 days", comment: "Subtitle shown on the reading challenge widget when the user has completed the challenge."),
            button1Title: family == .systemSmall
                ? WMFLocalizedString("reading-challenge-collect-prize-button-small", value: "Collect prize", comment: "Button title shown on the small reading challenge widget when the user has completed the challenge.")
                : WMFLocalizedString("reading-challenge-collect-prize-button", value: "Collect your prize!", comment: "Button title shown on the reading challenge widget when the user has completed the challenge."),
            button1URL: URL(string: "wikipedia://activity"),
            button1Icon: WMFSFSymbolIcon.for(symbol: .appGiftFill, font: .semiboldSubheadline),
            icon: WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1)
        )
    }

    static func incompleteSet(streak: Int) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.concluded.primary,
            color2: WMFTheme.ReadingChallengeColorSet.concluded.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.concluded.tertiary,
            image: "readingGlobe",
            title: WMFLocalizedString("reading-challenge-concluded-title", value: "Challenge Concluded", comment: "Title shown on the reading challenge widget when the challenge has ended."),
            subtitle: String.localizedStringWithFormat(
                WMFLocalizedString("reading-challenge-streak-of-days", value: "{{PLURAL:%1$d|%1$d of 25 day|%1$d of 25 days}}", comment: "Streak pill label shown on the reading challenge widget. %1$d is the number of days completed out of 25."),
                streak
            ),
            icon: nil,
            icon2: WMFSFSymbolIcon.for(symbol: .flameFill, font: .subheadline)
        )
    }

    static func noStreakSet() -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.concluded.primary,
            color2: WMFTheme.ReadingChallengeColorSet.concluded.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.concluded.tertiary,
            image: "readingGlobe",
            title: WMFLocalizedString("reading-challenge-concluded-title", value: "Challenge Concluded", comment: "Title shown on the reading challenge widget when the challenge has ended."),
            subtitle: nil
        )
    }

    static func notEnrolledSet(family: WidgetFamily) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.notEnrolled.primary,
            color2: WMFTheme.ReadingChallengeColorSet.notEnrolled.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.notEnrolled.tertiary,
            image: "readingGlobe",
            title: WMFLocalizedString(
                "reading-challenge-not-enrolled-title",
                value: "Ready, set, read!",
                comment: "Title shown on the reading challenge widget when the user is not enrolled in the challenge."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-not-enrolled-subtitle",
                value: "Join the 25-day challenge and unlock special prizes.",
                comment: "Subtitle shown on the reading challenge widget when the user is not enrolled in the challenge."
            ),
            button1Title: family == .systemSmall
                ? WMFLocalizedString("reading-challenge-join-button-small", value: "Join challenge", comment: "Button title on small widget.")
                : WMFLocalizedString("reading-challenge-join-button-medium", value: "Join the challenge", comment: "Button title on medium widget."),
            button2Title: nil,
            button1URL: URL(string: "wikipedia://activity?join=true"),
            button2URL: nil,
            button1Icon: nil,
            button2Icon: nil
        )
    }

    static func enrolledNotStartedSet(family: WidgetFamily) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.yellow.primary,
            color2: WMFTheme.ReadingChallengeColorSet.yellow.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.yellow.tertiary,
            image: "readingGlobe",
            title: family == .systemSmall ? "" : WMFLocalizedString(
                "reading-challenge-enrolled-not-started-title",
                value: "Ready, set, read!",
                comment: "Title shown on the reading challenge widget when enrolled but not yet started."
            ),
            subtitle: family == .systemSmall ? nil : WMFLocalizedString(
                "reading-challenge-enrolled-not-started-subtitle",
                value: "Start working towards a 25-day streak!",
                comment: "Subtitle shown on the reading challenge widget when enrolled but not yet started."
            ),
            button1Title: family == .systemSmall
                ? CommonStrings.exploreTabTitle
                : CommonStrings.searchTitle,
            button2Title: family == .systemSmall ? nil : WMFLocalizedString(
                "reading-challenge-random-button",
                value: "Random",
                comment: "Title for the Random article button on the reading challenge widget."
            ),
            button1URL: family == .systemSmall ? URL(string: "wikipedia://explore") : URL(string: "wikipedia://search"),
            button2URL: family == .systemSmall ? nil : URL(string: "wikipedia://random"),
            button1Icon: family == .systemSmall ? nil : WMFSFSymbolIcon.for(symbol: .magnifyingGlass, font: .semiboldSubheadline),
            button2Icon: family == .systemSmall ? nil : WMFSFSymbolIcon.for(symbol: .diceFill, font: .semiboldSubheadline)
        )
    }

    static func notLiveYetSet(family: WidgetFamily) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.green.primary,
            color2: WMFTheme.ReadingChallengeColorSet.green.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.green.tertiary,
            image: "readingGlobe",
            title: WMFLocalizedString(
                "reading-challenge-not-live-yet-title",
                value: "Get ready to read",
                comment: "Title shown on the reading challenge widget when the challenge has not yet launched."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-not-live-yet-subtitle",
                value: "A 25-day reading challenge is on the way.",
                comment: "Subtitle shown on the reading challenge widget when the challenge has not yet launched."
            ),
            button1Title: family == .systemSmall
                ? CommonStrings.exploreTabTitle
                : WMFLocalizedString(
                    "reading-challenge-explore-wikipedia-button",
                    value: "Explore Wikipedia",
                    comment: "Button title on the reading challenge widget linking to the Explore feed."
                  ),
            button1URL: URL(string: "wikipedia://explore"),
            button1Icon: nil
        )
    }

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
            return completedSet(family: family)
        case .challengeConcludedIncomplete(let streak):
            return incompleteSet(streak: streak)
        case .challengeConcludedNoStreak:
            return noStreakSet()
        case .notEnrolled:
            return notEnrolledSet(family: family)
        case .challengeRemoved:
            return notEnrolledSet(family: family)
        case .notLiveYet:
            return notLiveYetSet(family: family)
        case .enrolledNotStarted:
            return enrolledNotStartedSet(family: family)
        }
    }
}

// MARK: - Entry View

struct ReadingChallengeEntryView: View {
    let entry: ReadingChallengeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let displaySet = WMFReadingChallengeWidgetViewModel.DisplaySet.make(
            for: entry.state,
            family: family
        )
        return WMFReadingChallengeWidgetView(
            viewModel: WMFReadingChallengeWidgetViewModel(
                localizedStrings: WMFReadingChallengeWidgetViewModel.LocalizedStrings(
                    title: displaySet.title
                ),
                displaySet: displaySet,
                state: entry.state
            )
        )
        .containerBackground(for: .widget) {
            Color.clear
        }
        .widgetURL(URL(string: "wikipedia://explore"))
    }
}

// MARK: - Widget

struct ReadingChallengeWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.readingChallenge.identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingChallengeProvider()) { entry in
            ReadingChallengeEntryView(entry: entry)
        }
        .configurationDisplayName(WMFLocalizedString("reading-challenge-widget-display-name", value: "Reading Challenge", comment: "Display name for the reading challenge widget shown in the widget picker."))
        .description(WMFLocalizedString("reading-challenge-widget-description", value: "Track your reading challenge progress.", comment: "Description for the reading challenge widget shown in the widget picker."))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
