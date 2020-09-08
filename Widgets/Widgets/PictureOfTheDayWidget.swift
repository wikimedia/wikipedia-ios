import WidgetKit
import SwiftUI
import WMF
import UIKit

// TODO: Move into `PictureOfTheDay+LocalizedStrings.swift`
extension PictureOfTheDayWidget {

    enum LocalizedStrings {
        static let pictureOfTheDayWidgetTitle = WMFLocalizedString("potd-widget-title", value:"Picture of the day", comment: "Text for title of Picture of the day widget.")
        static let pictureOfTheDayWidgetDescription = WMFLocalizedString("potd-widget-description", value:"Enjoy a beautiful daily photo selected by our community.", comment: "Text for description of Picture of the day widget displayed when adding to home screen.")
    }

}


// MARK: - Widget

struct PictureOfTheDayWidget: Widget {
	private let kind: String = WidgetController.SupportedWidget.pictureOfTheDay.identifier

	public var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: PictureOfTheDayProvider(), content: { entry in
			PictureOfTheDayView(entry: entry)
		})
        .configurationDisplayName(PictureOfTheDayWidget.LocalizedStrings.pictureOfTheDayWidgetTitle)
        .description(PictureOfTheDayWidget.LocalizedStrings.pictureOfTheDayWidgetDescription)
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

// MARK: - Data

/// A data source and operation helper for all Picture of the day widget data
final class PictureOfTheDayData {

	// MARK: Properties

	static let shared = PictureOfTheDayData()

	private var imageInfoFetcher = MWKImageInfoFetcher()
	private var dataStore: MWKDataStore {
		MWKDataStore.shared()
	}

	let sampleEntry = PictureOfTheDayEntry(date: Date(), image: #imageLiteral(resourceName: "PictureOfTheYear_2019"), imageDescription: "Two bulls running while the jockey holds on to them in pacu jawi (from Minangkabau, \"bull race\"), a traditional bull race in Tanah Datar, West Sumatra, Indonesia. 2015, Final-45.")
	let placeholderEntry = PictureOfTheDayEntry(date: Date(), contentDate: nil, contentURL: nil, imageURL: nil, image: nil, imageDescription: nil)

	// MARK: Public

	func fetchLatestAvailablePictureEntry(usingImageCache: Bool = false, _ completion: @escaping (PictureOfTheDayEntry) -> Void) {
		// We could Result type the completion, but it's not probably worth the complexity for the widget's use cases
		guard let contentGroup = dataStore.viewContext.newestGroup(of: .pictureOfTheDay), let imageContent = contentGroup.contentPreview as? WMFFeedImage else {
			completion(sampleEntry)
			return
		}

		let sampleEntry = self.sampleEntry
		let contentDate = contentGroup.date
		let contentURL = contentGroup.url
		let imageThumbnailURL = imageContent.imageThumbURL
		let imageDescription = imageContent.imageDescription

		guard !usingImageCache else {
			if let cachedImage = ImageCacheController.shared?.memoryCachedImage(withURL: imageThumbnailURL) {
				let entry = PictureOfTheDayEntry(date: Date(), contentDate: contentDate, contentURL: contentURL, imageURL: imageThumbnailURL, image: cachedImage.staticImage, imageDescription: imageDescription)
				completion(entry)
			} else {
				completion(sampleEntry)
			}
			return
		}

		ImageCacheController.shared?.fetchImage(withURL: imageThumbnailURL, failure: { _ in
			completion(sampleEntry)
		}, success: { fetchedImage in
			let entry = PictureOfTheDayEntry(date: Date(), contentDate: contentDate, contentURL: contentURL, imageURL: imageThumbnailURL, image: fetchedImage.image.staticImage, imageDescription: imageDescription)
			completion(entry)
		})
	}

	// MARK: Private

	private func fetchImageLicense(forCanonicalPageTitle imageFile: String, _ completion: @escaping (MWKImageInfo?) -> Void) {
		imageInfoFetcher.fetchImageInfo(forCommonsFiles: [imageFile], failure: { error in
			completion(nil)
		}, success: { infoArray in
			guard let infoArray = infoArray as? [MWKImageInfo] else {
				completion(nil)
				return
			}

			if let _ = infoArray.first {
				// TODO: info.license
			} else {
				completion(nil)
			}
		})
	}

}

// MARK: - Model

struct PictureOfTheDayEntry: TimelineEntry {
	let date: Date // for Timeline Entry
	var contentDate: Date? = nil
	var contentURL: URL? = nil
	var imageURL: URL? = nil
	let image: UIImage?
	var imageDescription: String? = nil
	var license: MWKLicense? = nil
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
			let timeline = Timeline(entries: [entry], policy: .after(currentDate.dateAtMidnight() ?? currentDate))
			completion(timeline)
		}
	}

	func getSnapshot(in context: Context, completion: @escaping (PictureOfTheDayEntry) -> Void) {
		dataStore.fetchLatestAvailablePictureEntry(usingImageCache: context.isPreview) { entry in
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
						.overlay(PictureOfTheDayOverlayView(), alignment: .bottomLeading)
					description
						.frame(width: proxy.size.width, height: proxy.size.height * 0.23)
                        .background(Color(red: 34/255.0, green: 34/255.0, blue: 34/255.0))
				}
			default:
				image
					.frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
					.overlay(PictureOfTheDayOverlayView(), alignment: .bottomLeading)
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
            Image("Attribution")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 12)
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
