import Foundation
import Combine
import WMFData

@MainActor
public protocol WMFDiscoverEntryCardLoggingDelegate: AnyObject {
    func discoverEntryCardDidAppear()
    func discoverEntryCardDidTap()
}

/// The pinned Discover card at the top of the Saved tab. It opens the Discover reading list and
/// shows a dot while the current list has not been opened yet. One instance is shared by the All
/// articles and Reading lists segments.
@MainActor
public final class WMFDiscoverEntryCardViewModel: ObservableObject {

    @Published public private(set) var isVisible = false
    @Published public private(set) var hasUnseenList = false
    /// True while a new list is made. The card then shows a spinner in place of the collage, so
    /// the reader never sees the previous list change under their eyes.
    @Published public private(set) var isGenerating = false
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
    /// The generation the card started. It is never cancelled: the list belongs to the data controller.
    private(set) var generationTask: Task<Void, Never>?
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

    /// The card follows the list from anywhere in the app: a generation starting or ending, the list
    /// screen marking it seen, the Discover settings and the developer settings. Each notification
    /// only re-reads the state. Generation starts from `refresh()`, when Saved appears or the app
    /// comes to the foreground, and from Back on the Discover settings.
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

    /// Re-reads the Discover state and starts a generation when the list is due. Call it when Saved appears.
    public func refresh() {
        startRefresh(startsGenerationWhenDue: true)
    }

    /// Re-reads the Discover state without starting a generation.
    func reload() {
        startRefresh(startsGenerationWhenDue: false)
    }

    /// Cancels the refresh in flight and starts the next one when it ends. A cancelled refresh runs to
    /// its cancellation check without writing state, so the latest `refreshTask` covers every earlier one.
    private func startRefresh(startsGenerationWhenDue: Bool) {
        let previousRefreshTask = refreshTask
        previousRefreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await previousRefreshTask?.value
            await self?.performRefresh(startsGenerationWhenDue: startsGenerationWhenDue)
        }
    }

    private func performRefresh(startsGenerationWhenDue: Bool) async {
        guard discoverDataController.isEnabled else {
            isVisible = false
            return
        }
        let loadedSettings = await readingListDataController.settings
        guard loadedSettings.isEnabled else {
            isVisible = false
            return
        }
        let pages = (try? await readingListDataController.fetchCurrentRecommendations()) ?? []
        let loadedIsGenerating = await readingListDataController.isGenerating
        let loadedHasUnseenList = await readingListDataController.hasUnseenList
        guard !Task.isCancelled else { return }

        settings = loadedSettings
        hasUnseenList = loadedHasUnseenList
        isGenerating = loadedIsGenerating
        username = usernameProvider?()
        updateCollage(with: loadedIsGenerating ? [] : pages)
        // Like on Android, the card never opens on an empty list. It does show while the first list is made.
        isVisible = !pages.isEmpty || loadedIsGenerating

        if startsGenerationWhenDue, !loadedIsGenerating {
            startGenerationIfDue()
        }
    }

    /// Lets the data controller make a new list when one is due. The run posts the list state when
    /// it starts and when it ends, and each post re-reads the card. A failed run keeps the current
    /// list, and the next refresh tries again.
    private func startGenerationIfDue() {
        generationTask = Task { [readingListDataController] in
            _ = try? await readingListDataController.generateRecommendationsIfNeeded()
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
