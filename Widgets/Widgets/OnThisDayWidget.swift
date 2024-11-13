import WidgetKit
import SwiftUI
import WMF
import WMFComponents

// MARK: - Widget

struct OnThisDayWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.onThisDay.identifier

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OnThisDayProvider(), content: { entry in
            OnThisDayView(entry: entry)
        })
        .configurationDisplayName(CommonStrings.onThisDayTitle)
        .description(WMFLocalizedString("widget-onthisday-description", value: "Explore what happened on this day in history.", comment: "Description for 'On this day' view in iOS widget gallery"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

// MARK: - TimelineProvider

struct OnThisDayProvider: TimelineProvider {

    // MARK: Nested Types

    public typealias Entry = OnThisDayEntry

    // MARK: Properties

    private let dataStore = OnThisDayData.shared

    // MARK: TimelineProvider

    func placeholder(in: Context) -> OnThisDayEntry {
        return dataStore.placeholderEntryFromLanguage(nil)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OnThisDayEntry>) -> Void) {
        dataStore.fetchLatestAvailableOnThisDayEntry { entry in
            let currentDate = Date()
            let nextUpdate: Date
            if entry.error == nil && entry.isCurrent {
                nextUpdate = currentDate.randomDateShortlyAfterMidnight() ?? currentDate
            } else {
                let components = DateComponents(hour: 2)
                nextUpdate = Calendar.current.date(byAdding: components, to: currentDate) ?? currentDate
            }
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (OnThisDayEntry) -> Void) {
        dataStore.fetchLatestAvailableOnThisDayEntry(usingCache: context.isPreview) { entry in
            completion(entry)
        }
    }

}

/// A data source and operation helper for all On This Day of the day widget data
final class OnThisDayData {

    enum ErrorType {
        case noInternet, featureNotSupportedInLanguage

        var errorColor: Color {
            switch self {
            case .featureNotSupportedInLanguage:
                return Color(WMFColor.gray500)
            case .noInternet:
                return Color(WMFColor.gray800)
            }
        }

        var errorText: String {
            /// These are intentionally in the iOS system language, not the app's primary language. Everything else in this widget is in the app's primary language.
            switch self {
            case .featureNotSupportedInLanguage:
                return WMFLocalizedString("on-this-day-language-does-not-support-error", value: "Your primary Wikipedia language does not support On this day. You can update your primary Wikipedia in the app’s Settings menu.", comment: "Error message shown when the user's primary language Wikipedia does not have the 'On this day' feature.")
            case .noInternet:
                return WMFLocalizedString("on-this-day-no-internet-error", value: "No data available", comment: "error message shown when device is not connected to internet")
            }
        }
    }

    // MARK: Properties

    static let shared = OnThisDayData()

    // From https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/01/15, taken on 03 Sept 2020.
    func placeholderEntryFromLanguage(_ language: MWKLanguageLink?) -> OnThisDayEntry {
        let locale = NSLocale.wmf_locale(for: language?.languageCode)
        let isRTL = MWKLanguageLinkController.isLanguageRTL(forContentLanguageCode: language?.contentLanguageCode)

        let fullDate: String
        let eventYear: String
        let monthDay: String
        let calendar = NSCalendar.wmf_utcGregorian()
        let date = calendar?.date(from: DateComponents(year: 2001, month: 01, day: 15, hour: 0, minute: 0, second: 0))
        if let date = date {
            let fullDateFormatter = DateFormatter.wmf_longDateGMTFormatter(for: language?.languageCode)
            fullDate = fullDateFormatter.string(from: date)
            let yearWithEraFormatter = DateFormatter.wmf_yearGMTDateFormatter(for: language?.languageCode)
            eventYear = yearWithEraFormatter.string(from: date)
            let monthDayFormatter = DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: language?.languageCode)
            monthDay = monthDayFormatter.string(from: date)
        } else {
            fullDate = "January 15, 2001"
            eventYear = "2001"
            monthDay = "January 15"
        }

        let eventSnippet = WMFLocalizedString("widget-onthisday-placeholder-event-snippet", languageCode: language?.languageCode, value: "Wikipedia, a free wiki content encyclopedia, goes online.", comment: "Placeholder text for On This Day widget: Event describing launch of Wikipedia")
        let articleSnippet = WMFLocalizedString("widget-onthisday-placeholder-article-snippet", languageCode: language?.languageCode, value: "Free online encyclopedia that anyone can edit", comment: "Placeholder text for On This Day widget: Article description for an article about Wikipedia")

        // It seems that projects whose article is not titled "Wikipedia" (Arabic, for instance) all redirect this URL appropriately.
        let articleURL = URL(string: ((language?.siteURL.absoluteString ?? "https://en.wikipedia.org") + "/wiki/Wikipedia"))

        let entry: OnThisDayEntry = OnThisDayEntry(isRTLLanguage: isRTL,
                                          error: nil,

                                          onThisDayTitle: CommonStrings.onThisDayTitle(with: language?.languageCode),
                                          monthDay: monthDay,
                                          fullDate: fullDate,
                                          otherEventsText: CommonStrings.onThisDayFooterWith(with: 49, languageCode: language?.languageCode),
                                          contentURL: URL(string: "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today"),
                                          eventSnippet: eventSnippet,
                                          eventYear: eventYear,
                                          eventYearsAgo: String(format: WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: language?.languageCode), locale: locale, (Calendar.current.component(.year, from: Date()) - 2001)),
                                          articleTitle: CommonStrings.plainWikipediaName(with: language?.languageCode),
                                          articleSnippet: articleSnippet,
                                          articleImage: UIImage(named: "W"),
                                          articleURL: articleURL,
                                          yearRange: CommonStrings.onThisDayHeaderDateRangeMessage(with: language?.languageCode, locale: locale, lastEvent: "69", firstEvent: "2019"))
        return entry
    }

    // MARK: Public
    
    func fetchLatestAvailableOnThisDayEntry(usingCache: Bool = false, _ userCompletion: @escaping (OnThisDayEntry) -> Void) {
        let widgetController = WidgetController.shared
        widgetController.startWidgetUpdateTask(userCompletion) { (dataStore, widgetTaskCompletion) in
            guard let appLanguage = dataStore.languageLinkController.appLanguage,
                WMFOnThisDayEventsFetcher.isOnThisDaySupported(by: appLanguage.languageCode) else {
                let errorEntry = OnThisDayEntry.errorEntry(for: .featureNotSupportedInLanguage)
                widgetTaskCompletion(errorEntry)
                return
            }
            widgetController.fetchNewestWidgetContentGroup(with: .onThisDay, in: dataStore, isNetworkFetchAllowed: !usingCache) { (contentGroup) in
                guard let contentGroup = contentGroup else {
                    widgetTaskCompletion(self.placeholderEntryFromLanguage(dataStore.languageLinkController.appLanguage))
                    return
                }
                self.assembleOnThisDayFromContentGroup(contentGroup, dataStore: dataStore, usingImageCache: usingCache, completion: widgetTaskCompletion)
            }
        }
    }
    
    private func assembleOnThisDayFromContentGroup(_ contentGroup: WMFContentGroup, dataStore: MWKDataStore, usingImageCache: Bool = false, completion: @escaping (OnThisDayEntry) -> Void) {

        guard let previewEvents = contentGroup.contentPreview as? [WMFFeedOnThisDayEvent],
              let previewEvent = previewEvents.first,
              let entry = OnThisDayEntry(contentGroup)
        else {
            let language = dataStore.languageLinkController.appLanguage
            completion(placeholderEntryFromLanguage(language))
            return
        }
        
        let sendDataToWidget: (UIImage?) -> Void = { image in
            var entryWithImage = entry
            entryWithImage.articleImage = image
            completion(entryWithImage)
        }
        
        let imageURLRaw = previewEvent.articlePreviews?.first?.thumbnailURL
        guard let imageURL = imageURLRaw, !usingImageCache else {
                    /// The argument sent to `sendDataToWidget` on the next line could be nil because `imageURLRaw` is nil, or `cachedImage` returns nil.
                    /// `sendDataToWidget` will appropriately handle a nil image, so we don't need to worry about that here.
            let cachedImage = dataStore.cacheController.imageCache.cachedImage(withURL: imageURLRaw)?.staticImage
            sendDataToWidget(cachedImage)
            return
        }
        
        dataStore.cacheController.imageCache.fetchImage(withURL: imageURL, failure: { _ in
            sendDataToWidget(nil)
        }, success: { fetchedImage in
            sendDataToWidget(fetchedImage.image.staticImage)
        })
    }
    
    private func handleNoInternetError(_ completion: @escaping (OnThisDayEntry) -> Void) {
        let errorEntry = OnThisDayEntry.errorEntry(for: .noInternet)
        completion(errorEntry)
    }
}

// MARK: - Model

struct OnThisDayEntry: TimelineEntry {
    let date = Date()
    var isCurrent: Bool = false
    let isRTLLanguage: Bool
    let error: OnThisDayData.ErrorType?

    let onThisDayTitle: String
    let monthDay: String
    let fullDate: String
    let otherEventsText: String
    let contentURL: URL?
    let eventSnippet: String?
    let eventYear: String
    let eventYearsAgo: String?
    let articleTitle: String?
    let articleSnippet: String?
    var articleImage: UIImage?
    let articleURL: URL?
    let yearRange: String
}

extension OnThisDayEntry {
    init?(_ contentGroup: WMFContentGroup) {
        guard
            let midnightUTCDate = contentGroup.midnightUTCDate,
            let calendar = NSCalendar.wmf_utcGregorian(),
            let previewEvents = contentGroup.contentPreview as? [WMFFeedOnThisDayEvent],
            let previewEvent = previewEvents.first,
            let allEvents = contentGroup.fullContent?.object as? [WMFFeedOnThisDayEvent],
            let earliestEventYear = allEvents.last?.yearString,
            let latestEventYear = allEvents.first?.yearString,
            let article = previewEvents.first?.articlePreviews?.first,
            let year = previewEvent.year?.intValue,
            let eventsCount = contentGroup.countOfFullContent?.intValue
        else {
            return nil
        }
        let language = contentGroup.siteURL?.wmf_languageCode
        let monthDayFormatter = DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: language)
        monthDay = monthDayFormatter.string(from: midnightUTCDate)
        var components = calendar.components([.month, .year, .day], from: midnightUTCDate)
        components.year = year
        if let date = calendar.date(from: components) {
            let fullDateFormatter = DateFormatter.wmf_longDateGMTFormatter(for: language)
            fullDate = fullDateFormatter.string(from: date)
            let yearWithEraFormatter = DateFormatter.wmf_yearGMTDateFormatter(for: language)
            eventYear = yearWithEraFormatter.string(from: date)
        } else {
            fullDate = ""
            eventYear = ""
        }
        onThisDayTitle = CommonStrings.onThisDayTitle(with: language)
        isRTLLanguage = contentGroup.isRTL
        error = nil
        otherEventsText = CommonStrings.onThisDayFooterWith(with: (eventsCount - 1), languageCode: language)
        eventSnippet = previewEvent.text
        articleTitle = article.displayTitle
        articleSnippet = article.descriptionOrSnippet
        articleURL = article.articleURL
        let locale = NSLocale.wmf_locale(for: language)
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearsSinceEvent = currentYear - year
        eventYearsAgo = String(format: WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: language), locale: locale, yearsSinceEvent)
        yearRange = CommonStrings.onThisDayHeaderDateRangeMessage(with: language, locale: locale, lastEvent: earliestEventYear, firstEvent: latestEventYear)

        if let previewEventIndex = allEvents.firstIndex(of: previewEvent),
           let dynamicURL = URL(string: "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today?\(previewEventIndex)") {
            contentURL = dynamicURL
        } else {
            contentURL = URL(string: "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today")
        }
        isCurrent = contentGroup.isForToday
    }

    static func errorEntry(for error: OnThisDayData.ErrorType) -> OnThisDayEntry {
        let languageCode = Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        let isRTL = Locale.Language(identifier: languageCode).lineLayoutDirection == .rightToLeft
        let destinationURL = URL(string: "wikipedia://explore")
        return OnThisDayEntry(isRTLLanguage: isRTL, error: error, onThisDayTitle: "", monthDay: "", fullDate: "", otherEventsText: "", contentURL: destinationURL, eventSnippet: nil, eventYear: "", eventYearsAgo: nil, articleTitle: nil, articleSnippet: nil, articleImage: nil, articleURL: nil, yearRange: "")
    }
}
