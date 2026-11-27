import Foundation
import WMFData

public extension DateFormatter {

	/// Short time only: e.g. `2:48pm`
	static var wmfShortTimeFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .none
		return dateFormatter
	}()

	/// Short date and short time in the device locale: e.g. `10/2/26, 10:52 PM`
	static let wmfShortDateShortTimeFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
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

    /// Month and Day and two-digit Year: e.g. `August 22, 25`
    static var wmfMonthDayShortYearDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d yy")
        return dateFormatter
    }()

    /// Short month, day and year: e.g. `Aug 22, 2025`
    static var wmfShortMonthDayYearDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.locale = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d yyyy")
        return dateFormatter
    }()

    private static var wmfEventYearFormatters: [String: DateFormatter] = [:]

    /// The year of an On this day event in the language of `languageCode`: `1984`, or `44 BC` for
    /// a year before year 1. The feed gives a year before year 1 as a negative number with no
    /// year 0, so -44 is 44 BC. Thus the era is set, and the year is not counted back from year 0.
    static func wmfEventYearString(_ year: Int, languageCode: String?) -> String {
        let isBeforeYearOne = year < 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let key = "\(languageCode ?? "")|\(isBeforeYearOne)"
        let formatter: DateFormatter
        if let cached = wmfEventYearFormatters[key] {
            formatter = cached
        } else {
            formatter = DateFormatter()
            formatter.locale = Locale.formatting(forWikipediaLanguageCode: languageCode)
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.setLocalizedDateFormatFromTemplate(isBeforeYearOne ? "y G" : "y")
            wmfEventYearFormatters[key] = formatter
        }
        let components = DateComponents(era: isBeforeYearOne ? 0 : 1, year: abs(year))
        guard let date = calendar.date(from: components) else { return String(year) }
        return formatter.string(from: date)
    }

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

    /// Intended for VoiceOver labels:
    /// - If the date is today: spelled-out hours and minutes (e.g. "15 hours 40 minutes"),
    ///   avoiding punctuation like "15:40" which VoiceOver would enunciate character by character.
    /// - Otherwise: fallbacks to the same month and day rendering used visually,
    ///   which is already speech-friendly (e.g. "August 22").
    static func wmfLastReadAccessibilityLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let components = calendar.dateComponents([.hour, .minute], from: date)
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .spellOut
            formatter.allowedUnits = [.hour, .minute]
            formatter.zeroFormattingBehavior = .dropLeading
            if let spelledOut = formatter.string(from: components), !spelledOut.isEmpty {
                return spelledOut
            }
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

    /// Month and year in the numeric form of the locale, e.g. `09/2026`.
    static let monthYearNumericFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMyyyy")
        return formatter
    }()

    /// Month and year spelled out, e.g. `September 2026`.
    static let monthYearSpelledOutFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter
    }()
    
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()
    
    /// Parses a `yyyy-MM-dd` string and returns "Month Day, Year" e.g. `December 19, 2025`
    static func wmfMonthDayYearFromDailyGameDate(_ dateString: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: dateString) else { return dateString }
        return wmfMonthDayYearDateFormatter.string(from: date)
    }
}
