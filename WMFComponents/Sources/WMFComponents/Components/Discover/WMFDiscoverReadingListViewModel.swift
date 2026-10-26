import Foundation
import UIKit
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFDiscoverReadingListViewModel: ObservableObject {

    public enum State: Equatable {
        case loading
        case loaded
        case empty
        case error
    }

    public typealias SourceRect = CGRect

    @Published public private(set) var state: State = .loading
    @Published public private(set) var pages: [WMFDiscoverRecommendedPage] = []
    @Published public private(set) var settings: WMFDiscoverSettings = .default
    @Published private(set) var collageViewModel = WMFImageCollageViewModel(imageURLs: [])

    /// The permanent account name shown in the byline. Nil shows "Made for you".
    public let username: String?

    public var didTapArticle: ((WMFDiscoverRecommendedPage) -> Void)?
    public var didTapOpenInNewTab: ((WMFDiscoverRecommendedPage) -> Void)?
    public var didTapOpenInBackgroundTab: ((WMFDiscoverRecommendedPage) -> Void)?
    public var didTapShareArticle: ((WMFDiscoverRecommendedPage, SourceRect) -> Void)?
    public var didTapSaveList: (([WMFDiscoverRecommendedPage]) -> Void)?
    public var didTapShareList: (([WMFDiscoverRecommendedPage], SourceRect) -> Void)?
    /// Nil hides the "Customize Discover" menu item.
    public var didTapCustomize: (() -> Void)?
    /// Nil hides the "About this feature" menu item.
    public var didTapAbout: (() -> Void)?

    private let dataController: WMFDiscoverReadingListDataController
    private(set) var loadTask: Task<Void, Never>?

    public init(username: String?, dataController: WMFDiscoverReadingListDataController = .shared) {
        self.username = username
        self.dataController = dataController
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Loading

    /// Generates the list when it is due, then shows it. Call it once when the screen appears, and again to retry after an error.
    public func load() {
        loadTask?.cancel()
        state = .loading
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        do {
            settings = await dataController.settings
            let loadedPages: [WMFDiscoverRecommendedPage]
            do {
                loadedPages = try await dataController.generateRecommendationsIfNeeded()
            } catch WMFDiscoverReadingListDataController.DiscoverReadingListError.sourceHasNoArticles {
                loadedPages = try await dataController.fetchCurrentRecommendations()
            }
            guard !Task.isCancelled else { return }
            show(loadedPages)
            await showOnboardingToastIfNeeded()
        } catch {
            guard !Task.isCancelled else { return }
            state = .error
        }
    }

    private func show(_ loadedPages: [WMFDiscoverRecommendedPage]) {
        pages = loadedPages
        collageViewModel = WMFImageCollageViewModel(imageURLs: loadedPages.compactMap { page in
            page.thumbnailURL.map { ImageUtils.thumbnailURL(from: $0, width: Self.collageImageWidth) }
        })
        state = loadedPages.isEmpty ? .empty : .loaded
    }

    // MARK: - Toast

    private func showOnboardingToastIfNeeded() async {
        let hasShownOnboardingToast = await dataController.hasShownOnboardingToast
        guard !hasShownOnboardingToast else { return }
        try? await dataController.markOnboardingToastShown()
        WMFToastPresenter.shared.show(WMFToastConfig(title: onboardingToastTitle, duration: 5))
    }

    private var onboardingToastTitle: String {
        let format: String
        switch settings.cadence {
        case .daily:
            format = Self.onboardingToastDailyFormat
        case .weekly:
            format = Self.onboardingToastWeeklyFormat
        case .monthly:
            format = Self.onboardingToastMonthlyFormat
        }
        return String.localizedStringWithFormat(format, settings.articleCount)
    }

    // MARK: - Header text

    public var articleCountText: String {
        String.localizedStringWithFormat(CommonStrings.articleCountFormat, pages.count)
    }

    public var descriptionText: String {
        switch settings.cadence {
        case .daily:
            return Self.descriptionDaily
        case .weekly:
            return Self.descriptionWeekly
        case .monthly:
            return Self.descriptionMonthly
        }
    }

    // MARK: - Strings

    private static let onboardingToastDailyFormat = WMFLocalizedString("discover-list-onboarding-toast-daily", value: "{{PLURAL:%1$d|Discover will update with %1$d new article each day|Discover will update with %1$d new articles each day}}. Your recommendations are stored locally on your device.", comment: "Toast shown on the first visit to the Discover reading list when the list updates daily. %1$d is replaced with the number of articles in each list.")
    private static let onboardingToastWeeklyFormat = WMFLocalizedString("discover-list-onboarding-toast-weekly", value: "{{PLURAL:%1$d|Discover will update with %1$d new article each week|Discover will update with %1$d new articles each week}}. Your recommendations are stored locally on your device.", comment: "Toast shown on the first visit to the Discover reading list when the list updates weekly. %1$d is replaced with the number of articles in each list.")
    private static let onboardingToastMonthlyFormat = WMFLocalizedString("discover-list-onboarding-toast-monthly", value: "{{PLURAL:%1$d|Discover will update with %1$d new article each month|Discover will update with %1$d new articles each month}}. Your recommendations are stored locally on your device.", comment: "Toast shown on the first visit to the Discover reading list when the list updates monthly. %1$d is replaced with the number of articles in each list.")
    private static let descriptionDaily = WMFLocalizedString("discover-list-description-daily", value: "Your daily reading list. Learn about new topics, picked just for you. Updates each day.", comment: "Description under the title of the Discover reading list when the list updates daily.")
    private static let descriptionWeekly = WMFLocalizedString("discover-list-description-weekly", value: "Your weekly reading list. Learn about new topics, picked just for you. Updates at the beginning of the week.", comment: "Description under the title of the Discover reading list when the list updates weekly.")
    private static let descriptionMonthly = WMFLocalizedString("discover-list-description-monthly", value: "Your monthly reading list. Learn about new topics, picked just for you. Updates at the beginning of each month.", comment: "Description under the title of the Discover reading list when the list updates monthly.")

    // MARK: - Taps

    func tapArticle(_ page: WMFDiscoverRecommendedPage) {
        didTapArticle?(page)
    }

    func tapOpenInNewTab(_ page: WMFDiscoverRecommendedPage) {
        didTapOpenInNewTab?(page)
    }

    func tapOpenInBackgroundTab(_ page: WMFDiscoverRecommendedPage) {
        didTapOpenInBackgroundTab?(page)
    }

    func tapShareArticle(_ page: WMFDiscoverRecommendedPage, sourceRect: SourceRect) {
        didTapShareArticle?(page, sourceRect)
    }

    func tapSaveList() {
        guard !pages.isEmpty else { return }
        didTapSaveList?(pages)
    }

    func tapShareList(sourceRect: SourceRect) {
        guard !pages.isEmpty else { return }
        didTapShareList?(pages, sourceRect)
    }

    // MARK: - Images

    /// The width the collage asks for. The stored thumbnails are 160 pixels wide, too small for a tile that fills a third of the screen.
    static let collageImageWidth = 960
}
