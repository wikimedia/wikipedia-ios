import Foundation
import Combine
import WMFNativeLocalizations

// MARK: - Day Model

struct WMFDatePickerDay: Identifiable {
    let id: Date
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isInCurrentMonth: Bool
    let playedScore: Int?
    let isPaused: Bool
}

// MARK: - ViewModel

@MainActor
public final class WMFDatePickerViewModel: ObservableObject {

    // MARK: - Localized Strings

    public struct LocalizedStrings {
        public let title: String
        public let subtitle: String
        public let archiveLabel: String
        public let toastScoreFormat: String
        public let monthPickerA11y: String
        public let previousMonthA11y: String
        public let nextMonthA11y: String
        public let dayScoreA11yFormat: String
        public let dayPausedA11y: String
        public let dismissA11y: String
        /// When non-nil, overrides the system-derived weekday abbreviations.
        /// All 7 values must be provided, ordered Sun–Sat.
        public let weekdaySymbolOverrides: [String]?

        public init(
            title: String = WMFLocalizedString("which-came-first-archive-title", value: "Which came first?", comment: "Title for the Which Came First archive date picker sheet header."),
            subtitle: String = WMFLocalizedString("which-came-first-archive-subtitle", value: "Play games since June 2024.", comment: "Subtitle for the Which Came First archive date picker sheet header."),
            archiveLabel: String = WMFLocalizedString("which-came-first-archive-nav-title", value: "Archive", comment: "Label appended to the game title in the Which Came First archive date picker sheet header."),
            toastScoreFormat: String = WMFLocalizedString("which-came-first-archive-toast-score", value: "You scored %1$d/5 on this day.", comment: "Toast message shown when a user taps a completed day in the Which Came First archive date picker. %1$d is the user's score."),
            monthPickerA11y: String = WMFLocalizedString("which-came-first-archive-month-picker-a11y", value: "Select month and year", comment: "Accessibility label for the month/year button in the Which Came First archive date picker."),
            previousMonthA11y: String = WMFLocalizedString("which-came-first-archive-previous-month-a11y", value: "Previous month", comment: "Accessibility label for the previous month navigation button in the Which Came First archive date picker."),
            nextMonthA11y: String = WMFLocalizedString("which-came-first-archive-next-month-a11y", value: "Next month", comment: "Accessibility label for the next month navigation button in the Which Came First archive date picker."),
            dayScoreA11yFormat: String = WMFLocalizedString("which-came-first-archive-day-score-a11y", value: "Score: %1$d out of 5", comment: "Accessibility label suffix for a day cell in the Which Came First archive date picker that shows the user's score. %1$d is the numeric score."),
            dayPausedA11y: String = WMFLocalizedString("which-came-first-archive-day-paused-a11y", value: "Game in progress", comment: "Accessibility label suffix for a day cell in the Which Came First archive date picker indicating a paused game."),
            dismissA11y: String = WMFLocalizedString("which-came-first-archive-dismiss-a11y", value: "Close archive", comment: "Accessibility label for the close/dismiss button on the Which Came First archive date picker sheet."),
            weekdaySymbolOverrides: [String]? = nil
        ) {
            precondition(
                weekdaySymbolOverrides == nil || weekdaySymbolOverrides?.count == 7,
                "weekdaySymbolOverrides must contain exactly 7 symbols (Sun–Sat)"
            )
            self.title = title
            self.subtitle = subtitle
            self.archiveLabel = archiveLabel
            self.toastScoreFormat = toastScoreFormat
            self.monthPickerA11y = monthPickerA11y
            self.previousMonthA11y = previousMonthA11y
            self.nextMonthA11y = nextMonthA11y
            self.dayScoreA11yFormat = dayScoreA11yFormat
            self.dayPausedA11y = dayPausedA11y
            self.dismissA11y = dismissA11y
            self.weekdaySymbolOverrides = weekdaySymbolOverrides
        }
    }

    // MARK: Published

    @Published var displayedMonth: Date
    @Published var weeks: [[WMFDatePickerDay?]] = []
    @Published var toastMessage: String? = nil

    // MARK: Config

    public let localizedStrings: LocalizedStrings
    let archiveStartDate: Date

    var title: String { localizedStrings.title }
    var subtitle: String { localizedStrings.subtitle }

    // MARK: Private

    private let calendar: Calendar
    private var toastTimer: Timer?

    var onSelectDate: ((Date) -> Void)?

    // MARK: - Weekday Symbols

    /// Weekday abbreviations respecting locale first-day-of-week, with optional
    /// override from LocalizedStrings. System symbols come from the device locale
    /// via Calendar.current so they automatically translate (e.g. "LUN" in French).
    var weekdaySymbols: [String] {
        if let overrides = localizedStrings.weekdaySymbolOverrides {
            // Rotate the caller-supplied Sun–Sat array to match the
            // locale's firstWeekday so column order stays correct.
            return rotatedToFirstWeekday(overrides)
        }

        // Use shortWeekdaySymbols from the locale-aware calendar.
        // These are already ordered Sun–Sat in the symbols array, so we
        // rotate to match firstWeekday (e.g. Mon-first locales).
        let symbols = calendar.shortWeekdaySymbols.map { $0.uppercased() }
        return rotatedToFirstWeekday(symbols)
    }

    /// Rotates a Sun-indexed array of 7 symbols so index 0 aligns with
    /// the calendar's firstWeekday (1 = Sun, 2 = Mon, … 7 = Sat).
    private func rotatedToFirstWeekday(_ symbols: [String]) -> [String] {
        let offset = calendar.firstWeekday - 1   // 0 for Sun, 1 for Mon, etc.
        guard offset > 0 else { return symbols }
        return Array(symbols[offset...] + symbols[..<offset])
    }

    // MARK: Init

    public init(
        localizedStrings: LocalizedStrings = LocalizedStrings(),
        archiveStartDate: Date = DateComponents(calendar: .current, year: 2024, month: 6, day: 1).date!,
        playedDates: [Date: Int] = [:],
        pausedDates: Set<Date> = [],
        onSelectDate: ((Date) -> Void)? = nil
    ) {
        self.localizedStrings = localizedStrings
        self.archiveStartDate = archiveStartDate
        self.onSelectDate = onSelectDate

        var cal = Calendar.current
        self.calendar = cal

        let now = Date()
        self.displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        self._playedDates = playedDates
        self._pausedDates = pausedDates

        buildWeeks()
    }

    // MARK: Private storage

    private var _playedDates: [Date: Int]
    private var _pausedDates: Set<Date>

    // MARK: Public helpers

    var displayedMonthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "MMMM yyyy",
            options: 0,
            locale: .current
        )
        return fmt.string(from: displayedMonth)
    }

    // Guard to protect from out of range dates
    var canGoBack: Bool {
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return false }
        let archiveMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: archiveStartDate))!
        return prevMonth >= archiveMonth
    }

    var canGoForward: Bool {
        let now = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        return nextMonth <= currentMonth
    }

    // MARK: Navigation

    func goToPreviousMonth() {
        guard canGoBack,
              let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev
        buildWeeks()
    }

    func goToNextMonth() {
        guard canGoForward,
              let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
        buildWeeks()
    }

    // MARK: Selection

    func selectDay(_ day: WMFDatePickerDay) {
        guard day.isInCurrentMonth else { return }

        if let score = day.playedScore {
            showToast(String.localizedStringWithFormat(localizedStrings.toastScoreFormat, score))
        } else if day.isPaused {
            onSelectDate?(day.date)
        } else if day.date <= Date() && day.date >= archiveStartDate {
            onSelectDate?(day.date)
        }
    }

    // MARK: Toast

    private func showToast(_ message: String) {
        toastMessage = message
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.toastMessage = nil
            }
        }
    }

    // MARK: Grid Builder

    private func buildWeeks() {
        let today = calendar.startOfDay(for: Date())
        let firstOfMonth = displayedMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

        let rawWeekday = calendar.component(.weekday, from: firstOfMonth)  // 1 = Sun
        let firstWeekday = calendar.firstWeekday                            // 1 = Sun, 2 = Mon…
        let leadingEmpties = (rawWeekday - firstWeekday + 7) % 7

        var days: [WMFDatePickerDay?] = Array(repeating: nil, count: leadingEmpties)

        for dayOffset in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: firstOfMonth) else { continue }
            let normalised = calendar.startOfDay(for: date)
            let score = _playedDates[normalised]
            let paused = _pausedDates.contains(normalised)
            days.append(WMFDatePickerDay(
                id: normalised,
                date: normalised,
                dayNumber: dayOffset + 1,
                isToday: normalised == today,
                isInCurrentMonth: true,
                playedScore: score,
                isPaused: paused
            ))
        }

        let remainder = days.count % 7
        if remainder != 0 {
            days.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
        }

        weeks = stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
}
