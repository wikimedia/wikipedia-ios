import Foundation
import WMFNativeLocalizations

@MainActor
public final class WMFWhichCameFirstArchiveViewModel: ObservableObject {

    // MARK: - Localized Strings

    let title: String = WMFLocalizedString("which-came-first-archive-title", value: "Which came first?", comment: "Title for the Which Came First archive date picker sheet header.")
    let subtitle: String = WMFLocalizedString("which-came-first-archive-subtitle", value: "Play games since June 2024.", comment: "Subtitle for the Which Came First archive date picker sheet header.")
    let archiveLabel: String = WMFLocalizedString("which-came-first-archive-nav-title", value: "Archive", comment: "Label appended to the game title in the archive sheet header.")
    let toastScoreFormat: String = WMFLocalizedString("which-came-first-archive-toast-score", value: "You scored %1$d / 5 on this day.", comment: "Toast message shown when a user taps a completed day. %1$d is the numeric score out of 5.")
    let dayScoreA11yFormat: String = WMFLocalizedString("which-came-first-archive-day-score-a11y", value: "Score: %1$d out of 5", comment: "Accessibility label suffix for a completed game in a day cell showing the user's score. $1 is the user's numeric score out of 5.")

    // MARK: - Properties

    public let archiveStartDate: Date
    public let playedDates: [Date: Int]
    public let pausedDates: Set<Date>
    public let onSelectDate: ((Date) -> Void)?
    public var onShowScoreToast: ((String) -> Void)?

    // MARK: - Init

    public init(
        archiveStartDate: Date = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2024, month: 6, day: 1).date ?? Date(),
        playedDates: [Date: Int] = [:],
        pausedDates: Set<Date> = [],
        onSelectDate: ((Date) -> Void)? = nil
    ) {
        self.archiveStartDate = archiveStartDate
        self.playedDates = playedDates
        self.pausedDates = pausedDates
        self.onSelectDate = onSelectDate
    }

    // MARK: - Decorations

    // Only completed (played) games get a decoration — in-progress/paused days
    // are intentionally undecorated.
    var decoratedDateComponents: [DateComponents] {
        playedDates.keys.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }
    }

    func decorationAccessibilityLabel(for date: Date) -> String? {
        let normalised = Calendar.current.startOfDay(for: date)
        if let score = playedDates[normalised] {
            return String.localizedStringWithFormat(dayScoreA11yFormat, score)
        }
        return nil
    }

    // MARK: - Selection

    func selectDay(_ date: Date) {
        let normalised = Calendar.current.startOfDay(for: date)

        if let score = playedDates[normalised] {
            let message = String.localizedStringWithFormat(toastScoreFormat, score)
            onShowScoreToast?(message)
        } else if pausedDates.contains(normalised) || (normalised <= Date() && normalised >= archiveStartDate) {
            onSelectDate?(normalised)
        }
    }
}
