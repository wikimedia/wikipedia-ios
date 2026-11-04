import Combine
import UIKit
import WMF
import WMFComponents
import WMFData

/// What the badge needs to know about the Discover announcement. `WMFDiscoverDataController` is the
/// production source; tests pass a stub.
protocol SavedTabDiscoverAnnouncementProviding {
    var isEnabled: Bool { get }
    var shouldShowAnnouncement: Bool { get }
    func assignExperimentBucketIfNeeded() throws
}

extension WMFDiscoverDataController: SavedTabDiscoverAnnouncementProviding {
    func assignExperimentBucketIfNeeded() throws {
        try assignExperimentIfNeeded()
    }
}

/// The one owner of the Saved tab badge. Two states compete for the single badge slot: the
/// star that shows while saved articles download, and the dot that announces Discover until the
/// reader answers the onboarding card. The star wins while a download runs, because it is temporary.
@MainActor
final class SavedTabBadgeController {

    enum Badge: Equatable {
        case none
        case syncInProgress
        case discoverAnnouncement

        func value(for userInterfaceIdiom: UIUserInterfaceIdiom) -> String? {
            switch self {
            case .none:
                return nil
            case .syncInProgress:
                return "\u{2605}"
            case .discoverAnnouncement:
                return userInterfaceIdiom == .pad ? "\u{2800}" : "\u{25CF}"
            }
        }
    }

    private(set) var badge: Badge = .none

    private weak var tabBarItem: UITabBarItem?
    private weak var tabBar: UITabBar?
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private var theme: Theme
    private let discoverDataController: SavedTabDiscoverAnnouncementProviding

    private var isSyncInProgress = false
    private var showsDiscoverAnnouncement = false

    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressObservation: NSKeyValueObservation?
    private var showStarTask: Task<Void, Never>?
    private var discoverObservation: AnyCancellable?

    init(tabBarItem: UITabBarItem, tabBar: UITabBar?, theme: Theme, userInterfaceIdiom: UIUserInterfaceIdiom, discoverDataController: SavedTabDiscoverAnnouncementProviding = WMFDiscoverDataController.shared) {
        self.tabBarItem = tabBarItem
        self.tabBar = tabBar
        self.userInterfaceIdiom = userInterfaceIdiom
        self.theme = theme
        self.discoverDataController = discoverDataController
        beginProgressObservations()
        discoverObservation = NotificationCenter.default.publisher(for: WMFNSNotification.discoverAnnouncementStateDidChange)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshDiscoverAnnouncement()
                }
            }
        refreshDiscoverAnnouncement()
    }

    deinit {
        showStarTask?.cancel()
    }

    static func badge(isSyncInProgress: Bool, showsDiscoverAnnouncement: Bool) -> Badge {
        if isSyncInProgress {
            return .syncInProgress
        }
        return showsDiscoverAnnouncement ? .discoverAnnouncement : .none
    }

    // MARK: - Discover

    /// Re-reads the Discover gates. Rolls the experiment bucket on the first call while the feature is on.
    func refreshDiscoverAnnouncement() {
        if discoverDataController.isEnabled {
            try? discoverDataController.assignExperimentBucketIfNeeded()
        }
        showsDiscoverAnnouncement = discoverDataController.shouldShowAnnouncement
        render()
    }

    // MARK: - Theme

    /// Call after the tab bar takes a new theme, because the theme resets the badge color.
    func apply(theme: Theme) {
        self.theme = theme
        render(force: true)
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
        let newBadge = Self.badge(isSyncInProgress: isSyncInProgress, showsDiscoverAnnouncement: showsDiscoverAnnouncement)
        guard force || newBadge != badge else { return }
        badge = newBadge

        // The badge colors come from the tab bar appearance, and a badge that is already on
        // screen keeps its colors. Clear it, apply the colors, then set the value.
        tabBarItem?.badgeValue = nil
        if let tabBar, let style = badgeStyle(for: newBadge) {
            let appearance = tabBar.standardAppearance.copy()
            for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
                for state in [layout.normal, layout.selected] {
                    state.badgeBackgroundColor = style.background
                    state.badgeTextAttributes = style.textAttributes
                    state.badgePositionAdjustment = style.positionAdjustment
                }
            }
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
            tabBar.setNeedsLayout()
            tabBar.layoutIfNeeded()
        }
        tabBarItem?.badgeValue = newBadge.value(for: userInterfaceIdiom)
    }

    private struct BadgeStyle {
        let background: UIColor
        let textAttributes: [NSAttributedString.Key: Any]
        var positionAdjustment: UIOffset = .zero
    }

    private func badgeStyle(for badge: Badge) -> BadgeStyle? {
        switch badge {
        case .none:
            return nil
        case .syncInProgress:
            return BadgeStyle(background: theme.colors.accent, textAttributes: theme.tabBarItemBadgeTextAttributes)
        case .discoverAnnouncement:
            if userInterfaceIdiom == .pad {
                return BadgeStyle(background: theme.colors.destructive, textAttributes: theme.tabBarItemBadgeTextAttributes)
            }
            return BadgeStyle(
                background: .clear,
                textAttributes: [.foregroundColor: theme.colors.destructive],
                positionAdjustment: UIOffset(horizontal: WMFSpacing.xSmall, vertical: -WMFSpacing.xSmall)
            )
        }
    }
}
