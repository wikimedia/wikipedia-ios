import Foundation
import Combine

// MARK: - Day Model

struct WMFDatePickerDay: Identifiable {
    let id: Date
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isInCurrentMonth: Bool
    let playedScore: Int?
}

// MARK: - ViewModel

@MainActor
public final class WMFDatePickerViewModel: ObservableObject {

    // MARK: - Localized Strings

    public struct LocalizedStrings {
        public let title: String
        public let subtitle: String
        public let sundayAbbreviation: String
        public let mondayAbbreviation: String
        public let tuesdayAbbreviation: String
        public let wednesdayAbbreviation: String
        public let thursdayAbbreviation: String
        public let fridayAbbreviation: String
        public let saturdayAbbreviation: String

        public init(
            title: String = "Which came first?",
            subtitle: String = "Play games since June 2024.",
            sundayAbbreviation: String = "SUN",
            mondayAbbreviation: String = "MON",
            tuesdayAbbreviation: String = "TUE",
            wednesdayAbbreviation: String = "WED",
            thursdayAbbreviation: String = "THU",
            fridayAbbreviation: String = "FRI",
            saturdayAbbreviation: String = "SAT"
        ) {
            self.title = title
            self.subtitle = subtitle
            self.sundayAbbreviation = sundayAbbreviation
            self.mondayAbbreviation = mondayAbbreviation
            self.tuesdayAbbreviation = tuesdayAbbreviation
            self.wednesdayAbbreviation = wednesdayAbbreviation
            self.thursdayAbbreviation = thursdayAbbreviation
            self.fridayAbbreviation = fridayAbbreviation
            self.saturdayAbbreviation = saturdayAbbreviation
        }

        var weekdaySymbols: [String] {
            [sundayAbbreviation, mondayAbbreviation, tuesdayAbbreviation,
             wednesdayAbbreviation, thursdayAbbreviation, fridayAbbreviation,
             saturdayAbbreviation]
        }
    }

    // MARK: Published

    @Published var displayedMonth: Date
    @Published var weeks: [[WMFDatePickerDay?]] = []
    @Published var toastMessage: String? = nil

    // MARK: Config

    public let localizedStrings: LocalizedStrings
    /// Earliest selectable date (archive start)
    let archiveStartDate: Date

    var title: String { localizedStrings.title }
    var subtitle: String { localizedStrings.subtitle }

    // MARK: Private

    private let calendar: Calendar
    private var toastTimer: Timer?

    /// Closure called when user taps an unplayed, valid date
    var onSelectDate: ((Date) -> Void)?

    // MARK: Init

    public init(
        localizedStrings: LocalizedStrings = LocalizedStrings(),
        archiveStartDate: Date = DateComponents(calendar: .current, year: 2024, month: 6, day: 1).date!,
        playedDates: [Date: Int] = [:],
        onSelectDate: ((Date) -> Void)? = nil
    ) {
        self.localizedStrings = localizedStrings
        self.archiveStartDate = archiveStartDate
        self.onSelectDate = onSelectDate

        var cal = Calendar.current
        cal.firstWeekday = 1  // Sunday
        self.calendar = cal

        let now = Date()
        self.displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        self._playedDates = playedDates

        buildWeeks()
    }

    // MARK: Private storage

    private var _playedDates: [Date: Int]

    // MARK: Public helpers

    var displayedMonthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayedMonth)
    }

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
            showToast("You scored \(score)/5 on this day.")
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
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

        var days: [WMFDatePickerDay?] = []

        for _ in 1..<firstWeekday { days.append(nil) }

        for dayOffset in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: firstOfMonth) else { continue }
            let normalised = calendar.startOfDay(for: date)
            let score = _playedDates[normalised]
            days.append(WMFDatePickerDay(
                id: normalised,
                date: normalised,
                dayNumber: dayOffset + 1,
                isToday: normalised == today,
                isInCurrentMonth: true,
                playedScore: score
            ))
        }

        let remainder = days.count % 7
        if remainder != 0 {
            for _ in 0..<(7 - remainder) { days.append(nil) }
        }

        weeks = stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
}
