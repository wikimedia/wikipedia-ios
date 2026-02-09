import SwiftUI
import WMFComponents
import WidgetKit
import WMF
import WMFData

// MARK: - Widget

struct ReadingStreakWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.readingStreak.identifier

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingStreakProvider(), content: { entry in
            ReadingStreakWidgetView(entry: entry)
        })
        .configurationDisplayName(LocalizedStrings.widgetTitle)
        .description(LocalizedStrings.widgetDescription)
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Model

struct ReadingStreakEntry: TimelineEntry {
    var isPlaceholder: Bool = false
    let date: Date
    var streakCount: Int = 0
    var catImageData: Data? = nil
}

// MARK: - TimelineProvider

struct ReadingStreakProvider: TimelineProvider {

    // MARK: Nested Types

    public typealias Entry = ReadingStreakEntry

    // MARK: TimelineProvider

    func placeholder(in context: Context) -> ReadingStreakEntry {
        return ReadingStreakEntry(isPlaceholder: true, date: Date(), streakCount: 3, catImageData: nil)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingStreakEntry>) -> Void) {
        fetchReadingStreakEntry { entry in
            let currentDate = Date()
            let calendar = Calendar.current
            
            // Update after midnight (streak can only change daily)
            let nextUpdate: Date
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate),
               let midnight = calendar.date(bySettingHour: 0, minute: 5, second: 0, of: tomorrow) {
                nextUpdate = midnight
            } else {
                // Fallback: update in 12 hours
                nextUpdate = calendar.date(byAdding: .hour, value: 12, to: currentDate) ?? currentDate
            }

            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingStreakEntry) -> Void) {
        if context.isPreview {
            // Return placeholder for preview
            completion(placeholder(in: context))
        } else {
            fetchReadingStreakEntry(completion: completion)
        }
    }

    // MARK: - Private

    private func fetchReadingStreakEntry(completion: @escaping (ReadingStreakEntry) -> Void) {
        let widgetController = WidgetController.shared
        widgetController.fetchReadingStreakContent { result in
            switch result {
            case .success(let data):
                let entry = ReadingStreakEntry(
                    isPlaceholder: false,
                    date: Date(),
                    streakCount: data.streakCount,
                    catImageData: data.catImageData
                )
                completion(entry)
            case .failure:
                // Return placeholder on error
                completion(ReadingStreakEntry(isPlaceholder: true, date: Date(), streakCount: 0, catImageData: nil))
            }
        }
    }
}

// MARK: - Views

struct ReadingStreakWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var entry: ReadingStreakProvider.Entry
    
    private var theme: WMFTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        ZStack {
            Color(theme.paperBackground)
            
            HStack(spacing: 16) {
                // Cat image
                if let catImageData = entry.catImageData,
                   let uiImage = UIImage(data: catImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(theme.border), lineWidth: 1)
                        )
                } else if entry.isPlaceholder {
                    // Placeholder while loading
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(theme.midBackground))
                        .frame(width: 110, height: 110)
                }
                
                // Streak info
                VStack(alignment: .leading, spacing: 8) {
                    Text(ReadingStreakWidget.LocalizedStrings.streakTitle)
                        .font(Font(WMFFont.for(.boldHeadline)))
                        .foregroundColor(Color(theme.text))
                    
                    if entry.streakCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(entry.streakCount)")
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundColor(Color(theme.accent))
                            
                            Text(ReadingStreakWidget.LocalizedStrings.daysLabel)
                                .font(Font(WMFFont.for(.headline)))
                                .foregroundColor(Color(theme.secondaryText))
                        }
                        
                        Text(ReadingStreakWidget.LocalizedStrings.motivationalMessage(for: entry.streakCount))
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(theme.secondaryText))
                            .lineLimit(2)
                    } else {
                        Text(ReadingStreakWidget.LocalizedStrings.noStreakMessage)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(theme.secondaryText))
                            .lineLimit(3)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .clearWidgetContainerBackground()
    }
}

// MARK: - Localized Strings

extension ReadingStreakWidget {
    enum LocalizedStrings {
        static let widgetTitle = "Reading Streak"
        static let widgetDescription = "Track your daily reading with cute cats!"
        static let streakTitle = "Reading Streak"
        static let daysLabel = "days"
        static let noStreakMessage = "Start reading to begin your streak!"
        
        static func motivationalMessage(for streak: Int) -> String {
            switch streak {
            case 1:
                return "Great start! Keep it up!"
            case 2:
                return "Two days strong! 💪"
            case 3:
                return "Three day streak! You're on fire!"
            case 4:
                return "Four days! Halfway to a week!"
            case 5:
                return "Five days! Amazing progress!"
            case 6:
                return "Six days! Almost a full week!"
            case 7...:
                return "7+ day streak! You're a champion! 🏆"
            default:
                return ""
            }
        }
    }
}
