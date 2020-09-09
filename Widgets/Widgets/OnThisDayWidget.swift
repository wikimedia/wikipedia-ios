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
    let placeholderEntry = OnThisDayEntry(monthDay: "January 15", earliestYear: "69", latestYear: "2019", otherEventsCount: 49, contentURL: URL(string: "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today")!, eventSnippet: "Wikipedia, a free wiki content encyclopedia, goes online.", eventYear: 2001, articleTitle: "Wikipedia", articleSnippet: "Free online encyclopedia that anyone can edit", articleImage: UIImage(named: "W"), articleURL: URL(string: "https://en.wikipedia.org/wiki/Wikipedia"))

    // MARK: Public

    func fetchLatestAvailableOnThisDayEntry(usingCache: Bool = false, _ completion: @escaping (OnThisDayEntry) -> Void) {
//        if usingCache {
//            guard let contentGroup = dataStore.viewContext.newestGroup(of: .onThisDay), let imageContent = contentGroup.contentPreview as? WMFFeedOnThisDayEvent else {
//                completion(sampleEntry)
//                return
//            }

//            let contentDate = contentGroup.date
//            let contentURL = contentGroup.url
//            let imageThumbnailURL = imageContent.imageThumbURL
//            let imageDescription = imageContent.imageDescription
//
//            if let cachedImage = ImageCacheController.shared?.memoryCachedImage(withURL: imageThumbnailURL) {
//                let entry = PictureOfTheDayEntry(date: Date(), contentDate: contentDate, contentURL: contentURL, imageURL: imageThumbnailURL, image: cachedImage.staticImage, imageDescription: imageDescription)
//                completion(entry)
//            } else {
//                completion(sampleEntry)
//            }
//            return
//        }


        let now = Date()
        // TODO: Update next line to the language being used instead of nil
        let monthDay = DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: nil).string(from: now)
        let components = Calendar.current.dateComponents([.month, .day], from: now)
        guard let month = components.month, let day = components.day else {
            completion(placeholderEntry)
            return
        }

        let fetcher = WMFOnThisDayEventsFetcher()
        let blah: WMFErrorHandler = { error in
            //show error FIX ME HERE
        }

        let successCompletion: (([WMFFeedOnThisDayEvent]?) -> Void) = { events in
            events?.forEach({ $0.score = $0.calculateScore() })
            guard let events = events,
                  let topEvent = self.highestScoredEvent(events: events),
                  let topEventYearNSNumber = topEvent.year,
                  let topEventYear = Int(exactly: topEventYearNSNumber),
                  let topEventIndex = events.firstIndex(of: topEvent),
                  let destinationURL = URL(string:  "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today?\(topEventIndex)"),
                  let minYear = events.last?.yearString,
                  let maxYear = events.first?.yearString
            else {
                completion(self.placeholderEntry)
                return
            }

            let pageToPreview = self.bestArticleToDisplay(articles: topEvent.articlePreviews)

            let sendDataToWidget: ((UIImage?) -> Void) = { (image) in
                let onThisDayEntry = OnThisDayEntry(monthDay: monthDay,
                                                    earliestYear: minYear,
                                                    latestYear: maxYear,
                                                    otherEventsCount: events.count-1,
                                                    contentURL: destinationURL,
                                                    eventSnippet: topEvent.text ?? "",
                                                    eventYear: topEventYear,
                                                    articleTitle: pageToPreview?.displayTitle,
                                                    articleSnippet: pageToPreview?.descriptionOrSnippet,
                                                    articleImage: image,
                                                    articleURL: pageToPreview?.articleURL)
                completion(onThisDayEntry)
            }

            if let imageURL = pageToPreview?.thumbnailURL {
                DispatchQueue.main.async {
                    ImageCacheController.shared?.fetchImage(withURL: imageURL, failure: { _ in
                        sendDataToWidget(nil)
                    }, success: { fetchedImage in
                        sendDataToWidget(fetchedImage.image.staticImage)
                    })
                }
            } else {
                sendDataToWidget(nil)
            }
        }

        let siteURL = URL(string: "http://en.wikipedia.org/")! // update me!
        fetcher.fetchOnThisDayEvents(for: siteURL, month: UInt(month), day: UInt(day), failure: blah, success: successCompletion)
    }

    private func highestScoredEvent(events: [WMFFeedOnThisDayEvent]) -> WMFFeedOnThisDayEvent? {
        return events.max { a, b in (a.score?.floatValue ?? 0) < (b.score?.floatValue ?? 0) }
    }

    private func bestArticleToDisplay(articles: [WMFFeedArticlePreview]?) -> WMFFeedArticlePreview? {
        /// In `OnThisDayViewController`, we display articles in order supplied to the array. Thus, the first one is the one we show here.
        return articles?.first
    }
}

// MARK: - Model

struct OnThisDayEntry: TimelineEntry {
    let date = Date()

    let monthDay: String
    let earliestYear: String
    let latestYear: String
    let otherEventsCount: Int
    let contentURL: URL
    let eventSnippet: String?
    let eventYear: Int
    let articleTitle: String?
    let articleSnippet: String?
    let articleImage: UIImage?
    let articleURL: URL?
}
