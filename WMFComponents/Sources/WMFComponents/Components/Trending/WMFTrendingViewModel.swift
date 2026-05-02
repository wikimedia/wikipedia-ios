import Foundation
import UIKit
import WMFData

@MainActor
public final class WMFTrendingViewModel: ObservableObject {

    // MARK: - Types

    public enum Segment: String, CaseIterable {
        case byTopic
        case byArea
        case map
    }

    public struct ArticleRowViewModel: Identifiable {
        public let id: String
        public let title: String
        public let project: WMFProject
        public var description: String?
        public var thumbnailURLString: String?
        public var uiImage: UIImage?
        public var pageViews: Int?
    }

    public struct LocalizedStrings {
        public let navigationTitle: String
        public let byTopicSegment: String
        public let byAreaSegment: String
        public let mapSegment: String
        public let topicPickerTitle: String
        public let topicPickerDoneButton: String
        public let loadingMessage: String
        public let errorMessage: String
        public let noArticlesMessage: String

        public init(navigationTitle: String, byTopicSegment: String, byAreaSegment: String, mapSegment: String, topicPickerTitle: String, topicPickerDoneButton: String, loadingMessage: String, errorMessage: String, noArticlesMessage: String) {
            self.navigationTitle = navigationTitle
            self.byTopicSegment = byTopicSegment
            self.byAreaSegment = byAreaSegment
            self.mapSegment = mapSegment
            self.topicPickerTitle = topicPickerTitle
            self.topicPickerDoneButton = topicPickerDoneButton
            self.loadingMessage = loadingMessage
            self.errorMessage = errorMessage
            self.noArticlesMessage = noArticlesMessage
        }
    }

    // MARK: - Published Properties

    @Published public var selectedSegment: Segment = .byTopic
    @Published public var selectedTopics: Set<WMFTrendingTopic> = []
    @Published public var articleRows: [ArticleRowViewModel] = []
    @Published public var isLoading: Bool = false
    @Published public var isShowingTopicPicker: Bool = false
    @Published public var errorMessage: String? = nil

    // MARK: - Public Properties

    public let localizedStrings: LocalizedStrings
    public var onTapArticle: ((String, WMFProject) -> Void)?
    public var onTapCountry: ((WMFTrendingCountryAnnotation) -> Void)?
    public var detectedCountry: String { country }

    // MARK: - Private Properties

    private let dataController: WMFTrendingDataController
    private let languageCode: String
    private let country: String
    private var loadTask: Task<Void, Never>?

    // MARK: - Init

    public init(
        localizedStrings: LocalizedStrings,
        dataController: WMFTrendingDataController = WMFTrendingDataController.shared
    ) {
        self.localizedStrings = localizedStrings
        self.dataController = dataController

        let regionID = Locale.current.region?.identifier ?? "US"
        self.languageCode = WMFTrendingViewModel.languageCode(forRegion: regionID)
        self.country = Locale.current.localizedString(forRegionCode: regionID) ?? "United States"

        let savedRaw = UserDefaults.standard.stringArray(forKey: WMFUserDefaultsKey.trendingSelectedTopic.rawValue) ?? []
        let saved = Set(savedRaw.compactMap { WMFTrendingTopic(rawValue: $0) })
        self.selectedTopics = saved.isEmpty ? [.biographyWomen] : saved
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public Methods

    public func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    public func selectTopic(_ topic: WMFTrendingTopic) {
        if selectedTopics.contains(topic) {
            // Keep at least one topic selected
            if selectedTopics.count > 1 {
                selectedTopics.remove(topic)
            }
        } else {
            selectedTopics.insert(topic)
        }
        let rawValues = selectedTopics.map(\.rawValue)
        UserDefaults.standard.set(rawValues, forKey: WMFUserDefaultsKey.trendingSelectedTopic.rawValue)
    }

    public func applyTopicSelection() {
        isShowingTopicPicker = false
        load()
    }

    // MARK: - Private

    private func performLoad() async {
        // Map segment uses static country annotations — no network load needed.
        guard selectedSegment != .map else {
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        articleRows = []

        do {
            let articles: [WMFTrendingArticle]
            switch selectedSegment {
            case .byTopic:
                var seen = Set<String>()
                var merged: [WMFTrendingArticle] = []
                for topic in selectedTopics {
                    let results = try await dataController.fetchTrendingByTopic(topic, languageCode: languageCode)
                    for article in results where seen.insert(article.id).inserted {
                        merged.append(article)
                    }
                }
                articles = merged
            case .byArea:
                articles = try await dataController.fetchTrendingByCountry(country, languageCode: languageCode)
            case .map:
                articles = []
            }
            articleRows = articles.map { article in
                let project = WMFProject.wikipedia(WMFLanguage(languageCode: article.project, languageVariantCode: nil))
                return ArticleRowViewModel(id: article.id, title: article.displayTitle, project: project)
            }
            await fetchSummariesForRows()
        } catch {
            // Treat failures as empty results — topic API paths are prototype-only
            // and not all topics are guaranteed to return data
        }

        isLoading = false
    }

    // Maps ISO 3166-1 alpha-2 region codes to the primary Wikipedia language for that country.
    // Falls back to "en" for unmapped regions.
    private static func languageCode(forRegion region: String) -> String {
        let map: [String: String] = [
            // Portuguese
            "BR": "pt", "PT": "pt", "AO": "pt", "MZ": "pt",
            // Spanish
            "ES": "es", "MX": "es", "AR": "es", "CO": "es", "CL": "es",
            "PE": "es", "VE": "es", "EC": "es", "GT": "es", "CU": "es",
            "BO": "es", "DO": "es", "HN": "es", "PY": "es", "SV": "es",
            "NI": "es", "CR": "es", "PA": "es", "UY": "es",
            // French
            "FR": "fr", "BE": "fr", "CH": "fr", "CA": "fr",
            // German
            "DE": "de", "AT": "de",
            // Japanese
            "JP": "ja",
            // Chinese
            "CN": "zh", "TW": "zh", "HK": "zh",
            // Korean
            "KR": "ko",
            // Russian
            "RU": "ru", "BY": "ru", "KZ": "ru",
            // Arabic
            "SA": "ar", "EG": "ar", "AE": "ar", "IQ": "ar", "MA": "ar",
            // Italian
            "IT": "it",
            // Dutch
            "NL": "nl",
            // Polish
            "PL": "pl",
            // Swedish
            "SE": "sv",
            // Norwegian
            "NO": "no",
            // Danish
            "DK": "da",
            // Finnish
            "FI": "fi",
            // Turkish
            "TR": "tr",
            // Indonesian
            "ID": "id",
            // Hindi
            "IN": "hi",
            // Ukrainian
            "UA": "uk",
            // Czech
            "CZ": "cs",
            // Hungarian
            "HU": "hu",
            // Romanian
            "RO": "ro",
            // Greek
            "GR": "el",
            // Hebrew
            "IL": "he",
            // Thai
            "TH": "th",
            // Vietnamese
            "VN": "vi"
        ]
        return map[region] ?? "en"
    }

    private func fetchSummariesForRows() async {
        for i in articleRows.indices {
            guard !Task.isCancelled else { return }
            let row = articleRows[i]
            do {
                let summary = try await WMFArticleSummaryDataController.shared.fetchArticleSummary(
                    project: row.project,
                    title: row.title.replacingOccurrences(of: " ", with: "_")
                )
                articleRows[i].description = summary.description
                articleRows[i].thumbnailURLString = summary.thumbnailURL?.absoluteString
                if let thumbnailURL = summary.thumbnailURL {
                    let imageData = try await WMFImageDataController.shared.fetchImageData(url: thumbnailURL)
                    articleRows[i].uiImage = UIImage(data: imageData)
                }
            } catch {
                // Silently skip missing summaries; row still shows title
            }
            if case .wikipedia(let language) = row.project {
                articleRows[i].pageViews = await dataController.fetchYesterdayPageViews(
                    title: row.title,
                    languageCode: language.languageCode
                )
            }
        }
    }
}
