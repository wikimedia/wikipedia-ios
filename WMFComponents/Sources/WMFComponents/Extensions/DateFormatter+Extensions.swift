import Foundation

public extension DateFormatter {

	/// Short time only: e.g. `2:48pm`
	static var wmfShortTimeFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .none
		return dateFormatter
	}()

	/// Full date only: e.g. `Tuesday, August 22, 2023`
	static var wmfFullDateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .none
		dateFormatter.dateStyle = .full
		return dateFormatter
	}()

    /// Weekday and Month date only: e.g. `Tuesday, August 22`
    static var wmfWeekdayMonthDayDateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "EEEE, MMMM dd"
        return dateFormatter
    }()
    
    /// Month and Day only: e.g. `August 22`
    static var wmfMonthDayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter
    }()

    /// Smart formatter for "Last Read" dates:
    /// - If the date is today → show time (e.g. `2:48 PM`)
    /// - Otherwise → show month and day (e.g. `August 22`)
    static func wmfLastReadFormatter(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return wmfShortTimeFormatter.string(from: date)
        } else {
            return wmfMonthDayDateFormatter.string(from: date)
        }
    }
}
