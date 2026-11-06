import Foundation
import Combine
import WMFData

public protocol WMFDiscoverEntryCardLoggingDelegate: AnyObject {
    @MainActor func discoverEntryCardDidAppear()
    @MainActor func discoverEntryCardDidTap()
}

/// The pinned Discover card at the top of the Saved tab. It opens the Discover reading list and
/// shows a dot while the current list has not been opened yet. One instance is shared by the All
/// articles and Reading lists segments.
@MainActor
public final class WMFDiscoverEntryCardViewModel: ObservableObject {

    @Published public private(set) var isVisible = false
    @Published public private(set) var hasUnseenList = false
    @Published public private(set) var settings: WMFDiscoverSettings = .default
    /// The permanent account name shown in the byline. Nil shows "Made for you".
    @Published public private(set) var username: String?
    @Published private(set) var collageViewModel = WMFImageCollageViewModel(imageURLs: [], layout: .entryCard)

    public var didTap: (() -> Void)?
    /// Answers the permanent account name on every refresh, so a login or logout shows in the byline.
    public var usernameProvider: (() -> String?)?
    public weak var loggingDelegate: WMFDiscoverEntryCardLoggingDelegate?

    private let discoverDataController: WMFDiscoverDataController
    private let readingListDataController: WMFDiscoverReadingListDataController
    private(set) var refreshTask: Task<Void, Never>?
    private var notificationObservations = Set<AnyCancellable>()
    private var collageImageURLs: [URL] = []
    private var didLogImpression = false

    public init(
        discoverDataController: WMFDiscoverDataController = .shared,
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.discoverDataController = discoverDataController
        self.readingListDataController = readingListDataController
        observeNotifications(from: notificationCenter)
        refresh()
    }

    deinit {
        refreshTask?.cancel()
    }

    /// The card follows the list from anywhere in the app: generation on foreground, the list
    /// screen marking it seen, the Discover settings and the developer settings. A notification
    /// only re-reads the stored list. A generation that ends with an empty list posts the same
    /// notification, and generating again from it would loop.
    private func observeNotifications(from notificationCenter: NotificationCenter) {
        let notificationNames = [WMFNSNotification.discoverListStateDidChange, WMFNSNotification.discoverAnnouncementStateDidChange]
        for notificationName in notificationNames {
            notificationCenter.publisher(for: notificationName)
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.reload()
                    }
                }
                .store(in: &notificationObservations)
        }
    }

    // MARK: - Refresh

    /// Re-reads the Discover state and generates the list when it is due. Call it when Saved appears.
    public func refresh() {
        startRefresh(generatesList: true)
    }

    /// Re-reads the Discover state and the stored list without generating.
    func reload() {
        startRefresh(generatesList: false)
    }

    private func startRefresh(generatesList: Bool) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.performRefresh(generatesList: generatesList)
        }
    }

    private func performRefresh(generatesList: Bool) async {
        guard discoverDataController.isEnabled else {
            isVisible = false
            return
        }
        let loadedSettings = await readingListDataController.settings
        guard loadedSettings.isEnabled else {
            isVisible = false
            return
        }
        let pages = await loadPages(generatesList: generatesList)
        let loadedHasUnseenList = await readingListDataController.hasUnseenList
        guard !Task.isCancelled else { return }

        settings = loadedSettings
        hasUnseenList = loadedHasUnseenList
        username = usernameProvider?()
        updateCollage(with: pages)
        isVisible = true
    }

    /// Generates a new list when the current one is expired or missing, so the card never waits
    /// for the reader to open the list screen. Keeps the current list when the source has no articles.
    private func loadPages(generatesList: Bool) async -> [WMFDiscoverRecommendedPage] {
        guard generatesList else {
            return (try? await readingListDataController.fetchCurrentRecommendations()) ?? []
        }
        do {
            return try await readingListDataController.generateRecommendationsIfNeeded()
        } catch WMFDiscoverReadingListDataController.DiscoverReadingListError.sourceHasNoArticles {
            return (try? await readingListDataController.fetchCurrentRecommendations()) ?? []
        } catch {
            return []
        }
    }

    /// Keeps the collage while its images are the same, so the tiles do not reload on every visit.
    private func updateCollage(with pages: [WMFDiscoverRecommendedPage]) {
        let imageURLs = pages.compactMap { page in
            page.thumbnailURL.map { ImageUtils.thumbnailURL(from: $0, width: WMFDiscoverReadingListViewModel.collageImageWidth) }
        }
        guard imageURLs != collageImageURLs else { return }
        collageImageURLs = imageURLs
        collageViewModel = WMFImageCollageViewModel(imageURLs: imageURLs, layout: .entryCard)
    }

    // MARK: - Text

    public var descriptionText: String {
        WMFDiscoverReadingListViewModel.description(for: settings.cadence)
    }

    // MARK: - Events

    public func viewDidAppear() {
        guard isVisible, !didLogImpression else { return }
        didLogImpression = true
        loggingDelegate?.discoverEntryCardDidAppear()
    }

    public func tapCard() {
        loggingDelegate?.discoverEntryCardDidTap()
        didTap?()
    }
}
