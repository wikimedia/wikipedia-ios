import SwiftUI
import WidgetKit
import WMF

// MARK: - Widget

struct TopReadWidget: Widget {
	private let kind: String = WidgetController.SupportedWidget.topRead.identifier

	public var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: TopReadProvider(), content: { entry in
			TopReadView(entry: entry)
		})
		.configurationDisplayName(LocalizedStrings.topReadWidgetTitle)
		.description(LocalizedStrings.topReadWidgetDescription)
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
	}
}

// MARK: - Data

final class TopReadData {

	// MARK: Properties

	static let shared = TopReadData()

	let maximumRankedArticles = 4

	var placeholder: TopReadEntry {
		return TopReadEntry(date: Date())
	}

	// MARK: Public

	private var dataStore: MWKDataStore {
		MWKDataStore.shared()
	}

	func fetchLatestAvailableTopRead(_ completion: @escaping (TopReadEntry) -> Void) {
		guard
			let appLanguage = dataStore.languageLinkController.appLanguage,
			let topRead = dataStore.viewContext.group(of: .topRead, for: Date(), siteURL: appLanguage.siteURL()),
			let results = topRead.contentPreview as? [WMFFeedTopReadArticlePreview] else {
				completion(placeholder)
				return
		}

		var rankedElements: [TopReadEntry.RankedElement] = []

		for article in results {
			if let articlePreview = self.dataStore.fetchArticle(with: article.articleURL) {
				if let viewCounts = articlePreview.pageViewsSortedByDate {
					rankedElements.append(.init(title: article.displayTitle, description: article.wikidataDescription ?? article.snippet ?? "", articleURL: article.articleURL, thumbnailURL: article.thumbnailURL, viewCounts: viewCounts))
				}
			}
		}

		rankedElements = Array(rankedElements.prefix(maximumRankedArticles))

		let group = DispatchGroup()

		for (index, element) in rankedElements.enumerated() {
			group.enter()
			guard let thumbnailURL = element.thumbnailURL, let fetcher = ImageCacheController.shared else {
				group.leave()
				continue
			}

			fetcher.fetchImage(withURL: thumbnailURL, failure: { _ in
				group.leave()
			}, success: { fetchedImage in
				rankedElements[index].image = fetchedImage.image.staticImage
				group.leave()
			})
		}

		group.notify(queue: .main) {
			completion(TopReadEntry(date: Date(), rankedElements: rankedElements, groupURL: topRead.url))
		}
	}

}

// MARK: - Model

struct TopReadEntry: TimelineEntry {
	struct RankedElement: Identifiable {
		var id: String = UUID().uuidString

		let title: String
		let description: String
		var articleURL: URL? = nil
		var image: UIImage? = nil
		var thumbnailURL: URL? = nil
		let viewCounts: [NSNumber]
	}

	let date: Date // for Timeline Entry
	var rankedElements: [RankedElement] = Array(repeating: RankedElement.init(title: "–", description: "–", image: nil, viewCounts: [.init(floatLiteral: 0)]), count: 4)
	var groupURL: URL? = nil
}

// MARK: - TimelineProvider

struct TopReadProvider: TimelineProvider {

	// MARK: Nested Types

	public typealias Entry = TopReadEntry

	// MARK: Properties

	private let dataStore = TopReadData.shared

	// MARK: TimelineProvider

	func placeholder(in: Context) -> TopReadEntry {
		return dataStore.placeholder
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<TopReadEntry>) -> Void) {
		dataStore.fetchLatestAvailableTopRead { entry in
			let timeline = Timeline(entries: [entry], policy: .atEnd)
			completion(timeline)
		}
	}

	func getSnapshot(in context: Context, completion: @escaping (TopReadEntry) -> Void) {
		// TODO: Support context.isPreview
		dataStore.fetchLatestAvailableTopRead { entry in
			completion(entry)
		}
	}

}

// MARK: - Views

struct TopReadView: View {
	@Environment(\.widgetFamily) private var family
	@Environment(\.colorScheme) private var colorScheme

	var entry: TopReadProvider.Entry?

	@ViewBuilder
	var body: some View {
		GeometryReader { proxy in
			switch family {
			case .systemMedium:
				rowBasedWidget(.systemMedium)
					.widgetURL(entry?.groupURL)
			case .systemLarge:
				rowBasedWidget(.systemLarge)
					.widgetURL(entry?.groupURL)
			default:
				smallWidget
					.frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
					.overlay(TopReadOverlayView(rankedElement: entry?.rankedElements.first))
					.widgetURL(entry?.rankedElements.first?.articleURL)
			}
		}
	}

	// MARK: View Components

	@ViewBuilder
	var smallWidget: some View {
		if let image = entry?.rankedElements.first?.image {
			Image(uiImage: image).resizable().scaledToFill()
		} else {
			Rectangle()
				.foregroundColor(colorScheme == .dark ? Color.black : Color.white)
		}
	}

	@ViewBuilder
	func rowBasedWidget(_ family: WidgetFamily) -> some View {
		let showSparkline = family == .systemLarge ? true : false
		let rowCount = family == .systemLarge ? 4 : 2

		VStack(alignment: .leading, spacing: 8) {
			Text(TopReadWidget.LocalizedStrings.topReadWidgetTitle)
				.font(.headline)
			ForEach(entry?.rankedElements.indices.prefix(rowCount) ?? 0..<0) { elementIndex in
				if let articleURL = entry?.rankedElements[elementIndex].articleURL {
					Link(destination: articleURL, label: {
						elementRow(elementIndex, rowCount: rowCount, showSparkline: showSparkline)
					})
				} else {
					elementRow(elementIndex, rowCount: rowCount, showSparkline: showSparkline)
				}
			}
		}
		.padding(16)
	}

	@ViewBuilder
	func elementRow(_ index: Int, rowCount: Int, showSparkline: Bool = false) -> some View {
		let rankColor = colorScheme == .light ? Theme.light.colors.rankGradient.color(at: CGFloat(index)/CGFloat(rowCount)).asColor : Theme.dark.colors.rankGradient.color(at: CGFloat(index)/CGFloat(rowCount)).asColor
		GeometryReader { proxy in
			HStack(alignment: .center) {
				Circle()
					.strokeBorder(rankColor, lineWidth: 1)
					.frame(width: 22, height: 22, alignment: .leading)
					.overlay(
						Text("\(NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: index + 1)))")
							.font(.footnote)
							.fontWeight(.light)
							.foregroundColor(rankColor)
					)
					.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 7))
				VStack(alignment: .leading, spacing: 5) {
					Text("\(entry?.rankedElements[index].title ?? "–")")
						.font(.caption)
						.bold()
						.foregroundColor(Color(.label))
					Text("\(entry?.rankedElements[index].description ?? "–")")
						.lineLimit(2)
						.font(.caption)
						.foregroundColor(Color(.secondaryLabel))
					if showSparkline {
						Sparkline(style: .compactWithViewCount, timeSeries: entry?.rankedElements[index].viewCounts)
							.cornerRadius(4)
							.frame(height: proxy.size.height / 3.0, alignment: .leading)
					}
				}
				Spacer()
				elementImageOrPlaceholder(index)
					.frame(width: proxy.size.height / 1.1, height: proxy.size.height / 1.1, alignment: .trailing)
					.mask(
						RoundedRectangle(cornerRadius: 5, style: .continuous)
					)
			}
		}
	}

	@ViewBuilder
	func elementImageOrPlaceholder(_ elementIndex: Int) -> some View {
		if let image = entry?.rankedElements[elementIndex].image {
			Image(uiImage: image)
				.resizable()
				.aspectRatio(contentMode: .fill)
		} else {
			Rectangle().fill(Color.gray)
		}
	}
}

struct TopReadOverlayView: View {
	@Environment(\.colorScheme) var colorScheme

	var rankedElement: TopReadEntry.RankedElement?

	var isExpandedStyle: Bool {
		return rankedElement?.image == nil
	}

	var readersForegroundColor: Color {
		colorScheme == .light
			? Theme.light.colors.rankGradientEnd.asColor
			: Theme.dark.colors.rankGradientEnd.asColor
	}

	var primaryTextColor: Color {
		isExpandedStyle
			? colorScheme == .dark ? Color.white : Color.black
			: .white
	}

	private var currentViewCountOrEmpty: String {
		guard let currentViewCount = rankedElement?.viewCounts.last else {
			return "–"
		}

		return NumberFormatter.localizedThousandsStringFromNumber(currentViewCount)
	}

	var body: some View {
		if isExpandedStyle {
			content
		} else {
			content
				.background(
					Rectangle()
						.foregroundColor(.black)
						.mask(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .center, endPoint: .bottom))
						.opacity(0.35)
				)
		}
	}

	// MARK: View Components

	var content: some View {
		VStack(alignment: .leading) {
			sparkline(expanded: isExpandedStyle)
			Spacer()
			description(includeReaderCount: isExpandedStyle)
		}
		.foregroundColor(.white)
	}

	func sparkline(expanded: Bool) -> some View {
		HStack(alignment: .top) {
			Spacer()
			if expanded {
				Sparkline(style: .expanded, timeSeries: rankedElement?.viewCounts)
					.padding(EdgeInsets(top: 16, leading: 8, bottom: 0, trailing: 16))
			} else {
				Sparkline(style: .compact, timeSeries: rankedElement?.viewCounts)
					.cornerRadius(4)
					.frame(height: 20, alignment: .trailing)
					.padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 16))
					// TODO: Apply shadow just to final content – not children views as well
					// .clipped()
					// .readableShadow(intensity: 0.60)
			}
		}
	}

	func description(includeReaderCount: Bool = false) -> some View {
		VStack(alignment: .leading, spacing: 5) {
			Text(TopReadWidget.LocalizedStrings.topReadWidgetTitle)
				.font(.caption2)
				.fontWeight(.heavy)
				.aspectRatio(contentMode: .fit)
				.foregroundColor(primaryTextColor)
				.readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
			Text("\(rankedElement?.title ?? "–")")
				.lineLimit(nil)
				.font(.headline)
				.foregroundColor(primaryTextColor)
				.readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
			if includeReaderCount {
				// TODO: Localize
				Text("\(currentViewCountOrEmpty) Readers")
					.fontWeight(.bold)
					.lineLimit(nil)
					.font(.caption)
					.foregroundColor(readersForegroundColor)
					.readableShadow(intensity: isExpandedStyle ? 0 : 0.8)
			}
		}
		.padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
	}
}
