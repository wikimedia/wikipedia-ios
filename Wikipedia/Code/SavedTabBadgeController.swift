import Combine
import UIKit
import WMF
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

/// The one owner of the Saved tab bar badge. Two states compete for the single badge slot: the
/// star that shows while saved articles download, and the dot that announces Discover until the
/// reader answers the onboarding card. The star wins while a download runs, because it is temporary.
@MainActor
final class SavedTabBadgeController {

    enum Badge: Equatable {
        case none
        case syncInProgress
        case discoverAnnouncement

        var value: String? {
            switch self {
            case .none:
                return nil
            case .syncInProgress:
                return "\u{2605}"
            case .discoverAnnouncement:
                // The dot is drawn into the tab icon, not into the badge.
                return nil
            }
        }
    }

    /// Diameter of the Discover dot, in points.
    static let discoverDotDiameter: CGFloat = 10
    /// Room added around the tab icon so the dot can sit on its corner. Equal on every side, so the
    /// glyph stays centered in the tab.
    private static let discoverDotInset: CGFloat = 4

    private(set) var badge: Badge = .none

    private weak var tabBarItem: UITabBarItem?
    private weak var tabBar: UITabBar?
    private var theme: Theme
    /// The tab icon as the app set it, restored when the Discover dot goes away.
    private let baseImage: UIImage?
    private let discoverDataController: SavedTabDiscoverAnnouncementProviding

    private var isSyncInProgress = false
    private var showsDiscoverAnnouncement = false

    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressObservation: NSKeyValueObservation?
    private var showStarTask: Task<Void, Never>?
    private var discoverObservation: AnyCancellable?

    init(tabBarItem: UITabBarItem, tabBar: UITabBar?, theme: Theme, discoverDataController: SavedTabDiscoverAnnouncementProviding = WMFDiscoverDataController.shared) {
        self.tabBarItem = tabBarItem
        self.tabBar = tabBar
        self.theme = theme
        self.baseImage = tabBarItem.image
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

        // The badge color comes from the tab bar appearance, and a badge that is already on
        // screen keeps its color. Clear it, apply the color, then set the value.
        tabBarItem?.badgeValue = nil
        if let tabBar, let color = badgeColor(for: newBadge) {
            let appearance = tabBar.standardAppearance.copy()
            for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
                layout.normal.badgeBackgroundColor = color
                layout.selected.badgeBackgroundColor = color
            }
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
            tabBar.setNeedsLayout()
            tabBar.layoutIfNeeded()
        }
        tabBarItem?.badgeValue = newBadge.value
        renderIcon(for: newBadge)
    }

    /// Swaps the tab icon for a copy with the Discover dot, or puts the plain icon back.
    private func renderIcon(for badge: Badge) {
        guard let tabBarItem else { return }
        guard badge == .discoverAnnouncement, let baseImage else {
            tabBarItem.image = baseImage
            tabBarItem.selectedImage = nil
            return
        }
        tabBarItem.image = Self.dottedIcon(baseImage, iconColor: Self.unselectedIconColor(for: theme), dotColor: theme.colors.destructive)
        tabBarItem.selectedImage = Self.dottedIcon(baseImage, iconColor: theme.colors.link, dotColor: theme.colors.destructive)
    }

    /// Color of the other tab icons when they are not selected. The Liquid Glass tab bar ignores
    /// the normal `iconColor` of the appearance and draws template icons in the label color.
    private static func unselectedIconColor(for theme: Theme) -> UIColor {
        if #available(iOS 26.0, *) {
            return theme.colors.primaryText
        }
        return theme.colors.unselected
    }

    /// Draws `icon` in `iconColor` with a dot on its top trailing corner. The result keeps its own
    /// colors, so the tab bar does not tint it.
    static func dottedIcon(_ icon: UIImage, iconColor: UIColor, dotColor: UIColor) -> UIImage {
        let inset = discoverDotInset
        let diameter = discoverDotDiameter
        let canvasSize = CGSize(width: icon.size.width + inset * 2, height: icon.size.height + inset * 2)
        let iconRect = CGRect(origin: CGPoint(x: inset, y: inset), size: icon.size)
        let isRightToLeft = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        let dotCenterX = isRightToLeft ? iconRect.minX + inset / 2 : iconRect.maxX - inset / 2
        let dotRect = CGRect(x: dotCenterX - diameter / 2, y: iconRect.minY + inset / 2 - diameter / 2, width: diameter, height: diameter)

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { _ in
            icon.withTintColor(iconColor).draw(in: iconRect)
            dotColor.setFill()
            UIBezierPath(ovalIn: dotRect).fill()
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    private func badgeColor(for badge: Badge) -> UIColor? {
        switch badge {
        case .none:
            return nil
        case .syncInProgress:
            return theme.colors.accent
        case .discoverAnnouncement:
            return theme.colors.destructive
        }
    }
}
