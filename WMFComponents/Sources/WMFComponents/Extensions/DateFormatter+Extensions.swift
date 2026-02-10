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
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .none
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return dateFormatter
    }()
    
    /// Month and Day and Year only: e.g. `August 22, 2025`
    static var wmfMonthDayYearDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d yyyy")
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
    
    static let lastEditedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()
}
