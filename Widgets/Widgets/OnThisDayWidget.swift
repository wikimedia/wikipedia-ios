import WidgetKit
import SwiftUI
import WMF

// MARK: - Widget

struct OnThisDayWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.onThisDay.identifier

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OnThisDayProvider(), content: { entry in
            OnThisDayView(entry: entry)
        })
        .configurationDisplayName(WMFLocalizedString("widget-onthisday-name", value: "On this day", comment: "Name of 'On this day' view in iOS widget gallery"))
        .description(WMFLocalizedString("widget-onthisday-description", value: "Explore what happened on this day in history.", comment: "Description for 'On this day' view in iOS widget gallery"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        return dataStore.placeholderEntry
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OnThisDayEntry>) -> Void) {
        dataStore.fetchLatestAvailableOnThisDayEntry { entry in
            let currentDate = Date()
            let timeline = Timeline(entries: [entry], policy: .after(currentDate.dateAtMidnight() ?? currentDate))
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

    // MARK: Properties

    static let shared = OnThisDayData()

    private var imageInfoFetcher = MWKImageInfoFetcher()
    private var dataStore: MWKDataStore {
        MWKDataStore.shared()
    }

    // From https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/01/15, taken on 03 Sept 2020.
    let placeholderEntry = OnThisDayEntry(isRTLLanguage: false,
                                          hasConnectionError: false,
                                          doesLanguageSupportOnThisDay: true,
                                          monthDay: "January 15",
                                          fullDate: "January 15, 2001",
                                          otherEventsCount: 49,
                                          contentURL: URL(string: "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today")!,
                                          eventSnippet: "Wikipedia, a free wiki content encyclopedia, goes online.",
                                          eventYear: "2001",
                                          eventYearsAgo: "19 years ago",
                                          articleTitle: "Wikipedia",
                                          articleSnippet: "Free online encyclopedia that anyone can edit",
                                          articleImage: UIImage(named: "W"),
                                          articleURL: URL(string: "https://en.wikipedia.org/wiki/Wikipedia"),
                                          yearRange: CommonStrings.onThisDayHeaderDateRangeMessage(with: "en", locale: Locale(identifier: "en"), lastEvent: "69", firstEvent: "2019"))

    // MARK: Public

    private var siteURL: URL? {
        return dataStore.languageLinkController.appLanguage?.siteURL()
    }
    
    func fetchLatestAvailableOnThisDayEntry(usingCache: Bool = false, _ completion: @escaping (OnThisDayEntry) -> Void) {
        let moc = dataStore.viewContext
        moc.perform {
            guard let latest = moc.newestVisibleGroup(of: .onThisDay, forSiteURL: self.siteURL),
                  latest.isForToday
            else {
                guard !usingCache else {
                    completion(self.placeholderEntry)
                    return
                }
                self.fetchLatestOnThisDayEntryFromNetwork(completion)
                return
            }
            self.assembleOnThisDayFromContentGroup(latest, completion: completion)
        }
    }
    
    func fetchLatestOnThisDayEntryFromNetwork(_ completion: @escaping (OnThisDayEntry) -> Void) {
        dataStore.feedContentController.updateFeedSourcesUserInitiated(false) {
            let moc = self.dataStore.viewContext
            moc.perform {
                guard let latest = moc.newestVisibleGroup(of: .onThisDay, forSiteURL: self.siteURL) else {
                    // If there's no content even after a network fetch, it's likely an error
                    self.handleError(completion)
                    return
                }
                self.assembleOnThisDayFromContentGroup(latest, completion: completion)
            }
        }
    }
    
    func assembleOnThisDayFromContentGroup(_ contentGroup: WMFContentGroup, completion: @escaping (OnThisDayEntry) -> Void) {
        guard let previewEvents = contentGroup.contentPreview as? [WMFFeedOnThisDayEvent],
              let previewEvent = previewEvents.first
        else {
            completion(placeholderEntry)
            return
        }
        let sendDataToWidget: (UIImage?) -> Void = { image in
            guard let entry = OnThisDayEntry(contentGroup: contentGroup, image: image) else {
                completion(self.placeholderEntry)
                return
            }
            completion(entry)
        }
        if let imageURL = previewEvent.articlePreviews?.first?.thumbnailURL  {
            DispatchQueue.main.async {
                ImageCacheController.shared?.fetchImage(withURL: imageURL, failure: { _ in
                    sendDataToWidget(nil)
                }, success: { fetchedImage in
                    sendDataToWidget(fetchedImage.image.staticImage)
                })
            }
        }
    }
    
    func handleError(_ completion: @escaping (OnThisDayEntry) -> Void) {
        let isRTL = Locale.lineDirection(forLanguage: Locale.autoupdatingCurrent.languageCode ?? "en") == .rightToLeft
        let destinationURL = URL(string: "wikipedia://explore")!
        let errorEntry = OnThisDayEntry(isRTLLanguage: isRTL, hasConnectionError: true, doesLanguageSupportOnThisDay: false, monthDay: "", fullDate: "", otherEventsCount: 0, contentURL: destinationURL, eventSnippet: nil, eventYear: "", eventYearsAgo: nil, articleTitle: nil, articleSnippet: nil, articleImage: nil, articleURL: nil, yearRange: "")
        completion(errorEntry)
    }
}

// MARK: - Model

struct OnThisDayEntry: TimelineEntry {
    let date = Date()
    let isRTLLanguage: Bool

    let hasConnectionError: Bool
    let doesLanguageSupportOnThisDay: Bool

    let monthDay: String
    let fullDate: String
    let otherEventsCount: Int
    let contentURL: URL
    let eventSnippet: String?
    let eventYear: String
    let eventYearsAgo: String?
    let articleTitle: String?
    let articleSnippet: String?
    let articleImage: UIImage?
    let articleURL: URL?
    let yearRange: String
}

extension OnThisDayEntry {
    init?(contentGroup: WMFContentGroup, image: UIImage?) {
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
        let language = contentGroup.siteURL?.wmf_language
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
        isRTLLanguage = contentGroup.isRTL
        hasConnectionError = false
        doesLanguageSupportOnThisDay = true
        otherEventsCount = eventsCount - 1
        contentURL = URL(string: "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today")!
        eventSnippet = previewEvent.text
        articleTitle = article.displayTitle
        articleSnippet = article.descriptionOrSnippet
        articleImage = image
        articleURL = article.articleURL
        let locale = NSLocale.wmf_locale(for: language)
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearsSinceEvent = currentYear - year
        eventYearsAgo = String(format: WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: language), locale: locale, yearsSinceEvent)
        yearRange = CommonStrings.onThisDayHeaderDateRangeMessage(with: language, locale: locale, lastEvent: earliestEventYear, firstEvent: latestEventYear)
    }
}
