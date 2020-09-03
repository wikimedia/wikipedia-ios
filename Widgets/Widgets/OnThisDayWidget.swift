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

//    let sampleEntry = OnThisDayEntry(date: Date(), image: #imageLiteral(resourceName: "PictureOfTheYear_2019"), imageDescription: "Two bulls running while the jockey holds on to them in pacu jawi (from Minangkabau, \"bull race\"), a traditional bull race in Tanah Datar, West Sumatra, Indonesia. 2015, Final-45.")
    let placeholderEntry = OnThisDayEntry(date: Date(), snippet: "Blah", year: 2018, page: nil, pageImage: nil, earliestYear: "2015", latestYear: "2019", contentURL: URL(string: "http://www.google.com")!, otherEventsCount: 5)

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
            guard let events = events,
                  let topEvent = self.highestScoredEvent(events: events),
                  let topEventIndex = events.firstIndex(of: topEvent),
                  let destinationURL = URL(string:  "https://en.wikipedia.org/wiki/Wikipedia:On_this_day/Today?\(topEventIndex)"),
                  let minYear = events.last?.yearString,
                  let maxYear = events.first?.yearString
            else {
                completion(self.placeholderEntry)
                return
            }

            let pageToPreview = self.bestArticleToDisplay(articles: topEvent.articlePreviews)

            // REMOVE THIS FORCE UNWRPA ON NEXT ILNE
            let topEventYear: Int? = topEvent.yearString != nil ? Int(exactly: topEvent.year!) : nil

            let sendDataToWidget: ((UIImage?) -> Void) = { (image) in
                let onThisDayEntry = OnThisDayEntry(date: now,
                                                    snippet: topEvent.text ?? "",
                                                    year: topEventYear,
                                                    page: pageToPreview,
                                                    pageImage: image,
                                                    earliestYear: minYear,
                                                    latestYear: maxYear,
                                                    contentURL: destinationURL,
                                                    otherEventsCount: events.count-1)
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
        // TODO: This. And reuse code between here and existing code
        return events.first
    }

    private func bestArticleToDisplay(articles: [WMFFeedArticlePreview]?) -> WMFFeedArticlePreview? {
        return articles?.first
    }
}

// MARK: - Model

struct OnThisDayEntry: TimelineEntry {
    let date: Date

    let snippet: String?
    let year: Int?
    let page: WMFFeedArticlePreview?
    let pageImage: UIImage?
    let earliestYear: String
    let latestYear: String
    let contentURL: URL
    let otherEventsCount: Int
}

struct OnThisDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
