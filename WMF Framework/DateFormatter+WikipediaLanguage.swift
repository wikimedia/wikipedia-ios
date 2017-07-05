import Foundation

extension DateFormatter {
    // Returns year 'era' string - i.e. '1000 AD' or '200 BC'. (Negative years are 'BC')
    class func yearWithEraString(for year: Int, with wikipediaLanguage: String?) -> String? {
        var components = DateComponents()
        components.year = year
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        return DateFormatter.yearWithEraDateFormatter(for: wikipediaLanguage).string(from: date)
    }
    
    private static var yearWithEraDateFormatterCache: [String: DateFormatter] = [:]
    
    private static func yearWithEraDateFormatter(for wikipediaLanguage: String?) -> DateFormatter {
        let wikipediaLanguage = wikipediaLanguage ?? "en"
        if let formatter = yearWithEraDateFormatterCache[wikipediaLanguage] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguage)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("y G")
        yearWithEraDateFormatterCache[wikipediaLanguage] = dateFormatter
        return dateFormatter
    }
    
    private static var monthNameDayNumberFormatterCache: [String: DateFormatter] = [:]
    
    public static func monthNameDayNumberFormatter(for wikipediaLanguage: String?) -> DateFormatter {
        let wikipediaLanguage = wikipediaLanguage ?? "en"
        if let formatter = monthNameDayNumberFormatterCache[wikipediaLanguage] {
            return formatter
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.wmf_locale(for: wikipediaLanguage)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return dateFormatter
    }
}
