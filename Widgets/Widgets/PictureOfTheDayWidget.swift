import WidgetKit
import SwiftUI
import WMF
import UIKit

// MARK: - Widget

struct PictureOfTheDayWidget: Widget {
    private let kind: String = WidgetController.SupportedWidget.pictureOfTheDay.identifier

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PictureOfTheDayProvider(), content: { entry in
            PictureOfTheDayView(entry: entry)
        })
        .configurationDisplayName(PictureOfTheDayWidget.LocalizedStrings.widgetTitle)
        .description(PictureOfTheDayWidget.LocalizedStrings.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Data

/// A data source and operation helper for all Picture of the day widget data
final class PictureOfTheDayData {

    // MARK: Properties

    static let shared = PictureOfTheDayData()

    let sampleEntry = PictureOfTheDayEntry(date: Date(), image: #imageLiteral(resourceName: "PictureOfTheYear_2019"), imageDescription:  PictureOfTheDayWidget.LocalizedStrings.sampleEntryDescription)
    let placeholderEntry = PictureOfTheDayEntry(date: Date(), contentDate: nil, contentURL: nil, imageURL: nil, image: nil, imageDescription: nil)

    // MARK: Public

    func fetchLatestAvailablePictureEntry(usingCache: Bool = false, completion userCompletion: @escaping (PictureOfTheDayEntry) -> Void) {
        WidgetController.shared.startWidgetUpdateTask(userCompletion) { (dataStore, completion) in
            let moc = dataStore.viewContext
            moc.perform {
                guard let latest = moc.newestGroup(of: .pictureOfTheDay), latest.isForToday else {
                    guard !usingCache else {
                        completion(self.sampleEntry)
                        return
                    }
                    self.fetchLatestAvailablePictureEntryFromNetwork(with: dataStore, completion: completion)
                    return
                }
                self.assemblePictureEntryFromContentGroup(latest, dataStore: dataStore, usingImageCache: usingCache, completion: completion)
            }
        }
    }

    // MARK: Private

    private func fetchLatestAvailablePictureEntryFromNetwork(with dataStore: MWKDataStore, completion: @escaping (PictureOfTheDayEntry) -> Void) {
        dataStore.feedContentController.updateFeedSourcesUserInitiated(false) {
            let moc = dataStore.viewContext
            moc.perform {
                guard let latest = moc.newestGroup(of: .pictureOfTheDay) else {
                    completion(self.sampleEntry)
                    return
                }
                self.assemblePictureEntryFromContentGroup(latest, dataStore: dataStore, completion: completion)
            }
        }

    }

    private func assemblePictureEntryFromContentGroup(_ contentGroup: WMFContentGroup, dataStore: MWKDataStore, usingImageCache: Bool = false, completion: @escaping (PictureOfTheDayEntry) -> Void) {
        guard let imageContent = contentGroup.contentPreview as? WMFFeedImage else {
            completion(self.sampleEntry)
            return
        }

        let sampleEntry = self.sampleEntry
        let contentDate = contentGroup.date
        let contentURL = contentGroup.url
        let canonicalPageTitle = imageContent.canonicalPageTitle
        let imageThumbnailURL = imageContent.imageThumbURL
        let imageDescription = imageContent.imageDescription

        guard !usingImageCache else {
            if let cachedImage = dataStore.cacheController.imageCache.cachedImage(withURL: imageThumbnailURL) {
                let entry = PictureOfTheDayEntry(date: Date(), contentDate: contentDate, contentURL: contentURL, imageURL: imageThumbnailURL, image: cachedImage.staticImage, imageDescription: imageDescription)
                completion(entry)
            } else {
                completion(sampleEntry)
            }
            return
        }

        dataStore.cacheController.imageCache.fetchImage(withURL: imageThumbnailURL, failure: { _ in
            completion(sampleEntry)
        }, success: { fetchedImage in
            self.fetchImageLicense(from: dataStore, canonicalPageTitle: canonicalPageTitle) { license in
                let entry = PictureOfTheDayEntry(date: Date(), contentDate: contentDate, contentURL: contentURL, imageURL: imageThumbnailURL, image: fetchedImage.image.staticImage, imageDescription: imageDescription, licenseCode: license?.code)
                completion(entry)
            }
        })
    }
    
    var imageInfoFetcher: MWKImageInfoFetcher?
    private func fetchImageLicense(from dataStore: MWKDataStore, canonicalPageTitle: String, _ completion: @escaping (MWKLicense?) -> Void) {

        guard let siteURL = NSURL.wmf_wikimediaCommons() else {
            completion(nil)
            return
        }
        let fetcher = MWKImageInfoFetcher(dataStore: dataStore)
        imageInfoFetcher = fetcher // needs to be retained to complete the fetch
        fetcher.fetchGalleryInfo(forImage: canonicalPageTitle, fromSiteURL: siteURL, failure: { _ in
            self.imageInfoFetcher = nil
            DispatchQueue.main.async {
                completion(nil)
            }
        }, success: { imageInfo in
            self.imageInfoFetcher = nil
            guard let imageInfo = imageInfo as? MWKImageInfo, let license = imageInfo.license else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(license)
            }
        })
    }

}

// MARK: - Model

struct PictureOfTheDayEntry: TimelineEntry {

    // MARK: Nested Types

    struct LicenseImage: Identifiable {
        var id: String
        var image: UIImage // the system encodes this entry and it crashes if this is a SwiftUI.Image
    }

    // MARK: Properties

    let date: Date // for Timeline Entry
    var contentDate: Date? = nil
    var contentURL: URL? = nil
    var imageURL: URL? = nil
    let image: UIImage?
    var imageDescription: String? = nil
    var licenseCode: String? = nil // the system encodes this entry, avoiding bringing in the whole MWKLicense object and the Mantle dependency

    // MARK: License Image Parsing

    var licenseImages: [LicenseImage] {
        var licenseImages: [LicenseImage] = []
        let licenseCodes: [String] = licenseCode?.components(separatedBy: "-") ?? ["generic"]

        for license in licenseCodes {
            guard let image = UIImage(named: "license-\(license)") else {
                continue
            }
            licenseImages.append(LicenseImage(id: license, image: image))
        }

        return licenseImages
    }

}

// MARK: - TimelineProvider

struct PictureOfTheDayProvider: TimelineProvider {

    // MARK: Nested Types

    public typealias Entry = PictureOfTheDayEntry

    // MARK: Properties

    private let dataStore = PictureOfTheDayData.shared

    // MARK: TimelineProvider

    func placeholder(in: Context) -> PictureOfTheDayEntry {
        return dataStore.placeholderEntry
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PictureOfTheDayEntry>) -> Void) {
        dataStore.fetchLatestAvailablePictureEntry { entry in
            let currentDate = Date()
            let nextUpdate: Date
            let isError = (entry.imageDescription == dataStore.sampleEntry.imageDescription)
            if !isError {
                nextUpdate = currentDate.dateAtMidnight() ?? currentDate
            } else {
                let components = DateComponents(hour: 2)
                nextUpdate = Calendar.current.date(byAdding: components, to: currentDate) ?? currentDate
            }
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (PictureOfTheDayEntry) -> Void) {
        dataStore.fetchLatestAvailablePictureEntry(usingCache: context.isPreview) { entry in
            completion(entry)
        }
    }

}

// MARK: - Views

struct PictureOfTheDayView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PictureOfTheDayProvider.Entry

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch family {
            case .systemLarge:
                VStack(spacing: 0) {
                    image
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.77)
                        .overlay(PictureOfTheDayOverlayView(entry: entry), alignment: .bottomLeading)
                    description
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.23)
                        .background(Color(red: 34/255.0, green: 34/255.0, blue: 34/255.0))
                }
            default:
                image
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                    .overlay(PictureOfTheDayOverlayView(entry: entry), alignment: .bottomLeading)
            }
        }
        .widgetURL(entry.contentURL)
    }

    // MARK: View Components

    @ViewBuilder
    var image: some View {
        if let image = entry.image {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Rectangle()
                .foregroundColor(Color(.systemFill))
                .scaledToFill()
        }
    }

    var description: some View {
        let padding: CGFloat = 16

        return VStack {
            Spacer().frame(height: padding)
            GeometryReader { proxy in
                Text(entry.imageDescription ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: proxy.size.width, alignment: .leading)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
            }
            Spacer(minLength: padding)
        }
        .padding([.leading, .trailing], padding)
    }
}

struct PictureOfTheDayOverlayView: View {
    var entry: PictureOfTheDayEntry

    var body: some View {
        content
            .background(
                Rectangle()
                    .foregroundColor(.black)
                    .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .center, endPoint: .bottom))
                    .opacity(0.35)
            )
    }

    // MARK: - View Components

    var content: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Spacer()
                Image("W")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 16, alignment: .trailing)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 16))
                    .readableShadow()
            }
            Spacer()
            HStack(alignment: .top, spacing: 1) {
                ForEach(entry.licenseImages) { licenseImage in
                    Image(uiImage: licenseImage.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(height: 14)
            .readableShadow()
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 45))
        }
        .foregroundColor(.white)
    }
}

// MARK: - Preview

struct PictureOfTheDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        PictureOfTheDayView(entry: PictureOfTheDayData.shared.placeholderEntry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
