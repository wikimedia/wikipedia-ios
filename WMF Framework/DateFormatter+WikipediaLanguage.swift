import Foundation

extension DateFormatter {
    
    // Returns year string - i.e. '1000' or '200 BC'. (Negative years are 'BC')
    class func wmf_yearString(for year: Int, with wikipediaLanguageCode: String?) -> String? {
        var components = DateComponents()
        components.year = year
        let calendar = NSCalendar.wmf_utcGregorian()
        guard let date = calendar?.date(from: components) else {
            return nil
        }
        let formatter = year < 0 ? DateFormatter.wmf_yearWithEraGMTDateFormatter(for: wikipediaLanguageCode) : DateFormatter.wmf_yearGMTDateFormatter(for: wikipediaLanguageCode)
        return formatter.string(from: date)
    }
    
    private static var wmf_yearGMTDateFormatterCache: [String: DateFormatter] = [:]
    
    public static func wmf_yearGMTDateFormatter(for wikipediaLanguageCode: String?) -> DateFormatter {
        let wikipediaLanguageCode = wikipediaLanguageCode ?? "en"
        if let formatter = wmf_yearGMTDateFormatterCache[wikipediaLanguageCode] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguageCode)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("y")
        wmf_yearGMTDateFormatterCache[wikipediaLanguageCode] = dateFormatter
        return dateFormatter
    }
    
    private static var wmf_yearWithEraGMTDateFormatterCache: [String: DateFormatter] = [:]
    
    public static func wmf_yearWithEraGMTDateFormatter(for wikipediaLanguageCode: String?) -> DateFormatter {
        let wikipediaLanguageCode = wikipediaLanguageCode ?? "en"
        if let formatter = wmf_yearWithEraGMTDateFormatterCache[wikipediaLanguageCode] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguageCode)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("y G")
        wmf_yearWithEraGMTDateFormatterCache[wikipediaLanguageCode] = dateFormatter
        return dateFormatter
    }
    
    private static var wmf_monthNameDayNumberGMTFormatterCache: [String: DateFormatter] = [:]
    
    public static func wmf_monthNameDayNumberGMTFormatter(for wikipediaLanguageCode: String?) -> DateFormatter {
        let wikipediaLanguageCode = wikipediaLanguageCode ?? "en"
        if let formatter = wmf_monthNameDayNumberGMTFormatterCache[wikipediaLanguageCode] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguageCode)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d")
        wmf_monthNameDayNumberGMTFormatterCache[wikipediaLanguageCode] = dateFormatter
        return dateFormatter
    }
    
    private static var wmf_longDateGMTFormatterCache: [String: DateFormatter] = [:]

    public static func wmf_longDateGMTFormatter(for wikipediaLanguageCode: String?) -> DateFormatter {
        let wikipediaLanguageCode = wikipediaLanguageCode ?? "en"
        if let formatter = wmf_longDateGMTFormatterCache[wikipediaLanguageCode] {
            return formatter
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguageCode)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .long
        wmf_longDateGMTFormatterCache[wikipediaLanguageCode] = dateFormatter
        return dateFormatter
    }

}
