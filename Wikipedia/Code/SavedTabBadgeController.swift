import Combine
import UIKit
import WMF
import WMFData

/// What the badge needs to know about Discover. `WMFDiscoverDataController` is the production
/// source; tests pass a stub.
protocol SavedTabDiscoverProviding {
    var isEnabled: Bool { get }
    var shouldShowAnnouncement: Bool { get }
    var shouldShowUnseenListBadge: Bool { get }
    func assignExperimentBucketIfNeeded() throws
}

extension WMFDiscoverDataController: SavedTabDiscoverProviding {
    func assignExperimentBucketIfNeeded() throws {
        try assignExperimentIfNeeded()
    }
}

/// The one owner of the Saved tab badge. Two states compete for the single badge slot: the
/// star that shows while saved articles download, and the Discover dot. The dot announces Discover
/// until the reader answers the onboarding card, and later marks a Discover list the reader has
/// not opened yet. The star wins while a download runs, because it is temporary.
@MainActor
final class SavedTabBadgeController {

    enum Badge: Equatable {
        case none
        case syncInProgress
        case discover

        /// The dot is a badge with no text, which the tab bar draws as a plain circle.
        /// The iPad top tab bar draws no badge for an empty string, so it gets a blank glyph.
        func value(for userInterfaceIdiom: UIUserInterfaceIdiom) -> String? {
            switch self {
            case .none:
                return nil
            case .syncInProgress:
                return "\u{2605}"
            case .discover:
                return userInterfaceIdiom == .pad ? "\u{2800}" : ""
            }
        }
    }

    /// The badge colors belong to the tab bar appearance, so every badge on the bar shares them.
    /// The dot is red while it is the only badge. When another badge shows, all badges use the theme color.
    enum BadgeStyle: Equatable {
        case theme
        case alert
    }

    private(set) var badge: Badge = .none
    private(set) var badgeStyle: BadgeStyle?

    private weak var tabBarItem: UITabBarItem?
    private weak var tabBar: UITabBar?
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private var theme: Theme
    private let discoverDataController: SavedTabDiscoverProviding
    private let logDiscoverExperimentExposure: @MainActor () -> Void

    private var isSyncInProgress = false
    private var showsDiscoverDot = false
    private var hasOtherBadges = false

    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressObservation: NSKeyValueObservation?
    private var showStarTask: Task<Void, Never>?
    private var discoverObservation: AnyCancellable?

    init(tabBarItem: UITabBarItem, tabBar: UITabBar?, theme: Theme, userInterfaceIdiom: UIUserInterfaceIdiom, hasOtherBadges: Bool = false, discoverDataController: SavedTabDiscoverProviding = WMFDiscoverDataController.shared, logDiscoverExperimentExposure: @escaping @MainActor () -> Void = { DiscoverInstrumentation.shared.logExperimentExposure() }) {
        self.tabBarItem = tabBarItem
        self.tabBar = tabBar
        self.theme = theme
        self.userInterfaceIdiom = userInterfaceIdiom
        self.hasOtherBadges = hasOtherBadges
        self.discoverDataController = discoverDataController
        self.logDiscoverExperimentExposure = logDiscoverExperimentExposure
        beginProgressObservations()
        discoverObservation = NotificationCenter.default.publisher(for: WMFNSNotification.discoverAnnouncementStateDidChange)
            .merge(with: NotificationCenter.default.publisher(for: WMFNSNotification.discoverListStateDidChange))
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshDiscover()
                }
            }
        refreshDiscover()
    }

    deinit {
        showStarTask?.cancel()
    }

    static func badge(isSyncInProgress: Bool, showsDiscoverDot: Bool) -> Badge {
        if isSyncInProgress {
            return .syncInProgress
        }
        return showsDiscoverDot ? .discover : .none
    }

    static func badgeStyle(for badge: Badge, hasOtherBadges: Bool) -> BadgeStyle {
        badge == .discover && !hasOtherBadges ? .alert : .theme
    }

    /// Call this after the tab bar appearance changes. The theme replaces the badge colors.
    func apply(theme: Theme) {
        self.theme = theme
        badgeStyle = nil
        render(force: true)
    }

    /// Tell the controller before another tab shows its badge, and after it hides it. The dot color
    /// depends on it, and a badge takes the colors that the appearance has when it is set.
    func setHasOtherBadges(_ hasOtherBadges: Bool) {
        guard self.hasOtherBadges != hasOtherBadges else { return }
        self.hasOtherBadges = hasOtherBadges
        render()
    }

    // MARK: - Discover

    /// Re-reads the Discover gates. Rolls the experiment bucket on the first call while the feature
    /// is on, and sends the exposure event once the reader has a group.
    func refreshDiscover() {
        if discoverDataController.isEnabled {
            try? discoverDataController.assignExperimentBucketIfNeeded()
            logDiscoverExperimentExposure()
        }
        showsDiscoverDot = discoverDataController.shouldShowAnnouncement || discoverDataController.shouldShowUnseenListBadge
        render()
    }

    // MARK: - Sync

    func setSyncInProgress(_ isSyncInProgress: Bool) {
        guard self.isSyncInProgress != isSyncInProgress else { return }
        self.isSyncInProgress = isSyncInProgress
        render()
    }

    private func beginProgressObservations() {
        // A Progress is not reusable, so track each one the container publishes.
        progressObjectWasSetObservation = ProgressContainer.shared.observe(\ProgressContainer.articleFetcherProgress, options: [.new, .initial]) { [weak self] progressContainer, _ in
            let progress = progressContainer.articleFetcherProgress
            Task { @MainActor [weak self] in
                self?.track(progress)
            }
        }
    }

    private func track(_ progress: Progress?) {
        progressObservation?.invalidate()
        progressObservation = nil
        hideStar()

        guard let progress else {
            return
        }

        progressObservation = progress.observe(\Progress.fractionCompleted, options: [.new, .initial]) { [weak self] progress, _ in
            let shouldShow = progress.wmf_shouldShowProgressUI()
            Task { @MainActor [weak self] in
                self?.update(shouldShowStar: shouldShow)
            }
        }
    }

    private func update(shouldShowStar: Bool) {
        guard shouldShowStar else {
            hideStar()
            return
        }

        guard showStarTask == nil, !isSyncInProgress else {
            return
        }

        showStarTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(WMFMinProgressDurationBeforeShowingProgressUI))
            guard !Task.isCancelled else {
                return
            }
            self?.setSyncInProgress(true)
            self?.showStarTask = nil
        }
    }

    private func hideStar() {
        showStarTask?.cancel()
        showStarTask = nil
        setSyncInProgress(false)
    }

    // MARK: - Rendering

    private func render(force: Bool = false) {
        let newBadge = Self.badge(isSyncInProgress: isSyncInProgress, showsDiscoverDot: showsDiscoverDot)
        let newStyle = Self.badgeStyle(for: newBadge, hasOtherBadges: hasOtherBadges)
        guard force || newBadge != badge || newStyle != badgeStyle else { return }
        badge = newBadge

        // A badge that is on screen keeps its colors. Clear the badge, write the colors, then set the value again.
        tabBarItem?.badgeValue = nil
        if newStyle != badgeStyle {
            badgeStyle = newStyle
            writeAppearance(for: newStyle)
        }
        tabBarItem?.badgeValue = newBadge.value(for: userInterfaceIdiom)
    }

    private func writeAppearance(for style: BadgeStyle) {
        guard let tabBar else { return }
        let backgroundColor = style == .alert ? theme.colors.destructive : theme.colors.accent
        let appearance = tabBar.standardAppearance.copy()
        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            layout.normal.badgeBackgroundColor = backgroundColor
            layout.normal.badgeTextAttributes = theme.tabBarItemBadgeTextAttributes
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        // The bar reads the badge colors from the appearance in its next layout pass. A new appearance
        // does not request one, so a badge set after the write keeps the old colors without this call.
        tabBar.setNeedsLayout()
    }
}
