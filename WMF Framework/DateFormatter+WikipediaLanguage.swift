import Foundation

extension DateFormatter {
    // Returns year 'era' string - i.e. '1000 AD' or '200 BC'. (Negative years are 'BC')
    class func wmf_yearWithEraString(for year: Int, with wikipediaLanguage: String?) -> String? {
        var components = DateComponents()
        components.year = year
        let calendar = NSCalendar.wmf_utcGregorian()
        guard let date = calendar?.date(from: components) else {
            return nil
        }
        return DateFormatter.wmf_yearWithEraGMTDateFormatter(for: wikipediaLanguage).string(from: date)
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
}
