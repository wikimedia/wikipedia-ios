import Foundation

extension WMFLocalizedDateFormatStrings {
    @objc public static func yearsAgo(forWikiLanguage languageCode: String?) -> String {
        return WMFLocalizedString("relative-date-years-ago", languageCode: languageCode, value: "{{PLURAL:%1$d|0=This year|1=Last year|%1$d years ago}}", comment: "Relative years ago. 0 = this year, singular = last year. %1$d will be replaced with the number of years ago.")
    }
}
