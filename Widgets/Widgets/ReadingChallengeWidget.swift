import WidgetKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

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
        WMFDataEnvironment.current.testKitchenClient = TestKitchenAdapter.shared.client
        Task {
            let state = await resolvedState()

            let userDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")
            switch state {
            case .streakOngoingRead(let streak),
                 .streakOngoingNotYetRead(let streak),
                 .challengeConcludedIncomplete(let streak):
                userDefaults?.set(streak, forKey: "ReadingChallengeWidgetStreakCount")
            case .challengeCompleted:
                userDefaults?.set(ReadingChallengeStateConfig.streakGoal, forKey: "ReadingChallengeWidgetStreakCount")
            default:
                userDefaults?.removeObject(forKey: "ReadingChallengeWidgetStreakCount")
            }

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
        let inst: InstrumentImpl = {
            TestKitchenAdapter.shared.client.getInstrument(name: "apps-widgetchallenge")
                .setDefaultActionSource("widget")
                .startFunnel(name: "widget_challenge")
        }()
        
        do {
            let appContainerURL = FileManager.default.wmf_containerURL()
            WMFDataEnvironment.current.appContainerURL = appContainerURL

            let coreDataStore = try await WMFCoreDataStore(appContainerURL: appContainerURL)
            let controller = try WMFPageViewsDataController(coreDataStore: coreDataStore)
            
            UserDefaults(suiteName: "group.org.wikimedia.wikipedia")?.synchronize()
            
            let isEnrolled = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")?.bool(forKey: WMFUserDefaultsKey.hasEnrolledInReadingChallenge2026.rawValue) ?? false
            let currentDate = WMFDeveloperSettingsDataController.shared.devReadingChallengeCurrentDate ?? Date()
            return try await controller.fetchReadingChallengeState(isEnrolled: isEnrolled, now: currentDate, instrument: inst)
        } catch {
            return .notEnrolled
        }
    }
}

// MARK: - Display Sets

private extension WMFReadingChallengeWidgetViewModel.DisplaySet {
    
    static func randomIndex(indexKey: WMFUserDefaultsKey, dateKey: WMFUserDefaultsKey, optionsCount: Int) -> Int? {
        
        guard optionsCount > 0,
              let userDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia") else {
            return nil
        }
        
        let today = WMFDeveloperSettingsDataController.shared.devReadingChallengeCurrentDate ?? Calendar.current.startOfDay(for: Date())
        
        if userDefaults.object(forKey: indexKey.rawValue) == nil {
            userDefaults.set(0, forKey: indexKey.rawValue)
            userDefaults.set(today, forKey: dateKey.rawValue)
            return 0
        }
        
        let index =  userDefaults.integer(forKey: indexKey.rawValue)
       
        let lastDate = userDefaults.object(forKey: dateKey.rawValue) as? Date ?? .distantPast

        guard today > lastDate ||
               WMFDeveloperSettingsDataController.shared.devReadingChallengeState != nil else {
            // on same day, return old index without incrementing
            // but allow increment on same day if forcing a particular state
            return index
        }
        
        let nextIndex = (index + 1) % optionsCount
        userDefaults.set(nextIndex, forKey: indexKey.rawValue)
        userDefaults.set(today, forKey: dateKey.rawValue)
        return index
    }

    static func streakSet(streak: Int) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        
        let title = WMFLocalizedString("reading-challenge-streak-days", value: "{{PLURAL:%1$d|%1$d day|%1$d days}}", comment: "Number of days in a reading challenge streak. $1 is the number of days.")
        let subtitle = WMFLocalizedString("reading-challenge-subtitle", value: "25-day reading challenge", comment: "Subtitle shown on the reading challenge widget indicating the challenge length.")
        let icon = WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1)
        
        let defaultSet = WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.pink.primary,
            color2: WMFTheme.ReadingChallengeColorSet.pink.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.pink.tertiary,
            image: "phoneGlobe",
            title: String.localizedStringWithFormat(
                title,
                streak
            ),
            subtitle: subtitle,
            icon: icon
        )
        
        let displaySets = [
            defaultSet,
            WMFReadingChallengeWidgetViewModel.DisplaySet(
                color: WMFTheme.ReadingChallengeColorSet.purple.primary,
                color2: WMFTheme.ReadingChallengeColorSet.purple.secondary,
                color3: WMFTheme.ReadingChallengeColorSet.purple.tertiary,
                image: Int.random(in: 1...2) == 1 ? "musicGlobe1" : "musicGlobe2",
                title: String.localizedStringWithFormat(
                    title,
                    streak
                ),
                subtitle: subtitle,
                icon: icon
            ),
            WMFReadingChallengeWidgetViewModel.DisplaySet(
                color: WMFTheme.ReadingChallengeColorSet.blue.primary,
                color2: WMFTheme.ReadingChallengeColorSet.blue.secondary,
                color3: WMFTheme.ReadingChallengeColorSet.blue.tertiary,
                image: "spaceGlobe",
                title: String.localizedStringWithFormat(
                    title,
                    streak
                ),
                subtitle: subtitle,
                icon: icon
            )
        ]
        
        guard let index = randomIndex(indexKey: .readingChallengeStreakReadRandomIndex, dateKey: .readingChallengeStreakReadRandomIndexDate, optionsCount: displaySets.count) else {
            return defaultSet
        }
        
        return displaySets[index]
    }

    static func streakNotYetReadSet(streak: Int, showButtons: Bool, colorSet: WMFTheme.ReadingChallengeColorSet = .orange) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        

        let defaultSubtitleAndGlobe: (String, String) = (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-drift", value: "Don't let today drift by, your reading streak is waiting.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "sleepyGlobe")
        
        let sharedSubtitle = WMFLocalizedString("reading-challenge-not-yet-read-subtitle-article", value: "Your streak is just one article away.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today.")
        
        let subtitlesAndGlobes: [(String, String)] = [
            defaultSubtitleAndGlobe,
            (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-snooze", value: "Before the day snoozes away...there’s still time to learn something.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "sleepyGlobe"),
            (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-bit", value: "Even a small bit of reading counts towards your goal.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "sleepyGlobe"),
            (sharedSubtitle, "sleepyGlobe"),
            (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-jump", value: "Jump in for some reading anytime today.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "readingGlobe"),
            (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-quiet", value: "Quiet reading moment?", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "readingGlobe"),
            (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-curiosity", value: "Keep your curiosity going.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "readingGlobe"),
            (WMFLocalizedString("reading-challenge-not-yet-read-subtitle-curiosity", value: "Keep your curiosity going.", comment: "Subtitle shown on the reading challenge widget when the user has not yet read today."), "readingGlobe"),
            (sharedSubtitle, "readingGlobe")
        ]
        
        var subtitle = defaultSubtitleAndGlobe.0
        var globe = defaultSubtitleAndGlobe.1
        
        if let index = randomIndex(indexKey: .readingChallengeStreakNotReadRandomIndex, dateKey: .readingChallengeStreakNotReadRandomIndexDate, optionsCount: subtitlesAndGlobes.count) {
            subtitle = subtitlesAndGlobes[index].0
            globe = subtitlesAndGlobes[index].1
        }
        
        return WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: colorSet.primary,
            color2: colorSet.secondary,
            color3: colorSet.tertiary,
            image: globe,
            title: String.localizedStringWithFormat(
                WMFLocalizedString("reading-challenge-streak-days", value: "{{PLURAL:%1$d|%1$d day|%1$d days}}", comment: "Number of days in a reading challenge streak. $1 is the number of days."),
                streak
            ),
            subtitle: subtitle,
            button1Title: showButtons ? CommonStrings.searchTitle : nil,
            button2Title: showButtons ? WMFLocalizedString("reading-challenge-random-button", value: "Random", comment: "Title for the Random article button on the reading challenge widget.") : nil,
            button1URL: showButtons ? URL(string: "wikipedia://search") : nil,
            button2URL: showButtons ? URL(string: "wikipedia://random") : nil,
            button1Icon: showButtons ? WMFSFSymbolIcon.for(symbol: .magnifyingGlass, font: .semiboldSubheadline) : nil,
            button2Icon: showButtons ? WMFSFSymbolIcon.for(symbol: .diceFill, font: .semiboldSubheadline) : nil
        )
    }

    static func completedSet(family: WidgetFamily) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.blueBlack.primary,
            color2: WMFTheme.ReadingChallengeColorSet.blueBlack.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.blueBlack.tertiary,
            image: "partyGlobe",
            title: WMFLocalizedString("reading-challenge-completed-title", value: "You did it!", comment: "Title shown on the reading challenge widget when the user has completed the challenge."),
            subtitle: family == .systemSmall ? WMFLocalizedString("reading-challenge-completed-subtitle-small", value: "25 of 25", comment: "Subtitle shown on the reading challenge widget when the user has completed the challenge.") : WMFLocalizedString("reading-challenge-completed-subtitle", value: "25 of 25 days", comment: "Subtitle shown on the reading challenge widget when the user has completed the challenge."),
            button1Title: family == .systemSmall
                ? WMFLocalizedString("reading-challenge-collect-prize-button-small", value: "Collect prize", comment: "Short button title on small reading challenge widget when challenge is complete.")
                : CommonStrings.collectPrizeTitle,
            button1URL: URL(string: "wikipedia://activity?collectPrize=true"),
            icon: WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldFootnote)
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
        
        let defaultTitlesAndImage: (String, String, String) = (WMFLocalizedString("reading-challenge-enrolled-not-started-title-ready", value: "Ready, set, read!", comment: "Title shown on the reading challenge widget when enrolled but not yet started."), WMFLocalizedString(
            "reading-challenge-enrolled-not-started-subtitle-towards", value: "Start working towards a 25-day streak!", comment: "Subtitle shown on the reading challenge widget when enrolled but not yet started."), "readingGlobe")
        
        let titlesAndImages: [(String, String, String)] = [
            defaultTitlesAndImage,
            (WMFLocalizedString("reading-challenge-enrolled-not-started-title-start", value: "Start your reading challenge.", comment: "Title shown on the reading challenge widget when enrolled but not yet started."), WMFLocalizedString(
                "reading-challenge-enrolled-not-started-subtitle-somewhere", value: "Every streak starts somewhere.", comment: "Subtitle shown on the reading challenge widget when enrolled but not yet started."), "standingGlobe"),
            (WMFLocalizedString("reading-challenge-enrolled-not-started-title-spin", value: "Spin up a new streak?", comment: "Title shown on the reading challenge widget when enrolled but not yet started."), WMFLocalizedString(
                "reading-challenge-enrolled-not-started-subtitle-article", value: "Read one article to get started.", comment: "Subtitle shown on the reading challenge widget when enrolled but not yet started."), "synthGlobe1"),
            (WMFLocalizedString("reading-challenge-enrolled-not-started-title-fresh", value: "A fresh start.", comment: "Title shown on the reading challenge widget when enrolled but not yet started."), WMFLocalizedString(
                "reading-challenge-enrolled-not-started-subtitle-away", value: "Your streak is just one article away.", comment: "Subtitle shown on the reading challenge widget when enrolled but not yet started."), "synthGlobe2")
        ]
        
        var title = defaultTitlesAndImage.0
        var subtitle = defaultTitlesAndImage.1
        var image = defaultTitlesAndImage.2
        
        if let index = randomIndex(indexKey: .readingChallengeEnrolledNotStartedRandomIndex, dateKey: .readingChallengeEnrolledNotStartedRandomIndexDate, optionsCount: titlesAndImages.count) {
            title = titlesAndImages[index].0
            subtitle = titlesAndImages[index].1
            image = titlesAndImages[index].2
        }
        
        return WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: WMFTheme.ReadingChallengeColorSet.yellow.primary,
            color2: WMFTheme.ReadingChallengeColorSet.yellow.secondary,
            color3: WMFTheme.ReadingChallengeColorSet.yellow.tertiary,
            image: image,
            title: family == .systemSmall ? "" : title,
            subtitle: family == .systemSmall ? nil : subtitle,
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
            button1Icon: family == .systemSmall ? nil : WMFSFSymbolIcon.for(symbol: .magnifyingGlass, font: .caption1),
            button2Icon: family == .systemSmall ? nil : WMFSFSymbolIcon.for(symbol: .diceFill, font: .caption1)
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
            return noStreakSet()
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
