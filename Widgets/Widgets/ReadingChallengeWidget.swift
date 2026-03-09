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

// MARK: - Widget

struct ReadingChallengeWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.readingChallenge.identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingChallengeProvider()) { entry in
            ReadingChallengeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Reading Challenge")
        .description("Track your reading challenge progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - View

struct ReadingChallengeWidgetEntryView: View {
    let entry: ReadingChallengeEntry

    var body: some View {
        WMFReadingChallengeWidgetView(
            viewModel: WMFReadingChallengeWidgetViewModel(
                localizedStrings: WMFReadingChallengeWidgetViewModel.LocalizedStrings(
                    title: "Reading Challenge",
                    subtitle: "Track your progress"
                )
            )
        )
    }
}
