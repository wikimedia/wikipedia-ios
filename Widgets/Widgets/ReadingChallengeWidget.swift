import WidgetKit
import SwiftUI
import WMF
import WMFComponents

// MARK: - Entry

struct ReadingChallengeEntry: TimelineEntry {
    let date: Date
}

// MARK: - Provider

struct ReadingChallengeProvider: TimelineProvider {

    func placeholder(in context: Context) -> ReadingChallengeEntry {
        ReadingChallengeEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingChallengeEntry) -> Void) {
        completion(ReadingChallengeEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingChallengeEntry>) -> Void) {
        let entry = ReadingChallengeEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Display Sets

private extension WMFReadingChallengeWidgetViewModel.DisplaySet {
    static let streakOngoingReadSets: [WMFReadingChallengeWidgetViewModel.DisplaySet] = [
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: Color(red: 245/255, green: 235/255, blue: 242/255),
            color2: Color(red: 130/255, green: 69/255, blue: 106/255),
            image: "globe1",
            title: "3 days",
            subtitle: "25-day reading challenge"
        ),
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: Color(red: 245/255, green: 235/255, blue: 242/255),
            color2: Color(red: 130/255, green: 69/255, blue: 106/255),
            image: "globe1",
            title: "3 days",
            subtitle: "25-day reading challenge"
        )
    ]

    static let streakOngoingNotYetReadSets: [WMFReadingChallengeWidgetViewModel.DisplaySet] = [
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: .orange,
            color2: .orange,
            image: "globe1",
            title: ""
        )
    ]

    static let challengeConcludedCompletedSets: [WMFReadingChallengeWidgetViewModel.DisplaySet] = [
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: Color(red: 182/255, green: 212/255, blue: 251/255),
            color2: Color(red: 10/255, green: 36/255, blue: 77/255),
            image: "globe1",
            title: "25 of 25",
            subtitle: nil,
            button1Title: "Collect prize",
            button1URL: URL(string: "wikipedia://activity")
        )
    ]

    static let challengeConcludedIncompleteSets: [WMFReadingChallengeWidgetViewModel.DisplaySet] = [
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: .red,
            color2: .red,
            image: "globe1",
            title: ""
        )
    ]

    static let challengeConcludedNoStreakSets: [WMFReadingChallengeWidgetViewModel.DisplaySet] = [
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: .gray,
            color2: .gray,
            image: "globe1",
            title: ""
        )
    ]

    static let notEnrolledSets: [WMFReadingChallengeWidgetViewModel.DisplaySet] = [
        WMFReadingChallengeWidgetViewModel.DisplaySet(
            color: .gray,
            color2: .gray,
            image: "globe1",
            title: ""
        )
    ]

    static func random(for state: ReadingChallengeState) -> WMFReadingChallengeWidgetViewModel.DisplaySet {
        switch state {
        case .streakOngoingRead:
            return streakOngoingReadSets.randomElement()!
        case .streakOngoingNotYetRead:
            return streakOngoingNotYetReadSets.randomElement()!
        case .challengeConcludedCompletedSuccessfully:
            return challengeConcludedCompletedSets.randomElement()!
        case .challengeConcludedIncomplete:
            return challengeConcludedIncompleteSets.randomElement()!
        case .challengeConcludedNoStreak:
            return challengeConcludedNoStreakSets.randomElement()!
        case .notEnrolled:
            return notEnrolledSets.randomElement()!
        }
    }
}

// MARK: - Widget

struct ReadingChallengeWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.readingChallenge.identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingChallengeProvider()) { entry in
            let state = ReadingChallengeState.challengeConcludedCompletedSuccessfully
            WMFReadingChallengeWidgetView(
                viewModel: WMFReadingChallengeWidgetViewModel(
                    localizedStrings: WMFReadingChallengeWidgetViewModel.LocalizedStrings(
                        title: "3 days"
                    ),
                    displaySet: .random(for: state),
                    state: state
                )
            )
        }
        .configurationDisplayName("Reading Challenge")
        .description("Track your reading challenge progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
