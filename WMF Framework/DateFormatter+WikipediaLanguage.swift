import Foundation

extension DateFormatter {
    
    // Returns year string - i.e. '1000' or '200 BC'. (Negative years are 'BC')
    class func wmf_yearString(for year: Int, with wikipediaLanguage: String?) -> String? {
        var components = DateComponents()
        components.year = year
        let calendar = NSCalendar.wmf_utcGregorian()
        guard let date = calendar?.date(from: components) else {
            return nil
        }
        let formatter = year < 0 ? DateFormatter.wmf_yearWithEraGMTDateFormatter(for: wikipediaLanguage) : DateFormatter.wmf_yearGMTDateFormatter(for: wikipediaLanguage)
        return formatter.string(from: date)
    }
    
    private static var wmf_yearGMTDateFormatterCache: [String: DateFormatter] = [:]
    
    public static func wmf_yearGMTDateFormatter(for wikipediaLanguage: String?) -> DateFormatter {
        let wikipediaLanguage = wikipediaLanguage ?? "en"
        if let formatter = wmf_yearGMTDateFormatterCache[wikipediaLanguage] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguage)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("y")
        wmf_yearGMTDateFormatterCache[wikipediaLanguage] = dateFormatter
        return dateFormatter
    }
    
    private static var wmf_yearWithEraGMTDateFormatterCache: [String: DateFormatter] = [:]
    
    public static func wmf_yearWithEraGMTDateFormatter(for wikipediaLanguage: String?) -> DateFormatter {
        let wikipediaLanguage = wikipediaLanguage ?? "en"
        if let formatter = wmf_yearWithEraGMTDateFormatterCache[wikipediaLanguage] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguage)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("y G")
        wmf_yearWithEraGMTDateFormatterCache[wikipediaLanguage] = dateFormatter
        return dateFormatter
    }
    
    private static var wmf_monthNameDayNumberGMTFormatterCache: [String: DateFormatter] = [:]
    
    public static func wmf_monthNameDayNumberGMTFormatter(for wikipediaLanguage: String?) -> DateFormatter {
        let wikipediaLanguage = wikipediaLanguage ?? "en"
        if let formatter = wmf_monthNameDayNumberGMTFormatterCache[wikipediaLanguage] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguage)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d")
        wmf_monthNameDayNumberGMTFormatterCache[wikipediaLanguage] = dateFormatter
        return dateFormatter
    }
    
    private static var wmf_longDateGMTFormatterCache: [String: DateFormatter] = [:]

    public static func wmf_longDateGMTFormatter(for wikipediaLanguage: String?) -> DateFormatter {
        let wikipediaLanguage = wikipediaLanguage ?? "en"
        if let formatter = wmf_longDateGMTFormatterCache[wikipediaLanguage] {
            return formatter
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguage)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .long
        wmf_longDateGMTFormatterCache[wikipediaLanguage] = dateFormatter
        return dateFormatter
    }

}
