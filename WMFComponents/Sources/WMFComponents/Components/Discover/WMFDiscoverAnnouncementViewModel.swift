import Foundation
import WMFData

/// The impression has no callback here. The Saved screen logs it with its own impression, each
/// time the card is on screen.
@MainActor
public protocol WMFDiscoverAnnouncementLoggingDelegate: AnyObject {
    func discoverAnnouncementDidTapGetStarted()
    func discoverAnnouncementDidTapNoThanks()
}

/// The onboarding card that introduces Discover on the Saved tab. One instance is shared by the
/// All articles and Reading lists segments, so No thanks on one hides it on both. Get started
/// keeps the card: it only opens the setup flow, and the card goes away once Discover is on.
@MainActor
public final class WMFDiscoverAnnouncementViewModel: ObservableObject {

    @Published public private(set) var isVisible: Bool

    public var didTapGetStarted: (() -> Void)?
    public var didTapNoThanks: (() -> Void)?
    /// Called after the card is answered, when the Saved tab badge needs to update.
    public var didDismiss: (() -> Void)?
    public weak var loggingDelegate: WMFDiscoverAnnouncementLoggingDelegate?

    private let dataController: WMFDiscoverDataController

    public init(dataController: WMFDiscoverDataController = .shared) {
        self.dataController = dataController
        self.isVisible = dataController.shouldShowAnnouncement
    }

    /// Re-reads the persisted state, for example after the developer settings change.
    public func refresh() {
        isVisible = dataController.shouldShowAnnouncement
    }

    public func tapGetStarted() {
        loggingDelegate?.discoverAnnouncementDidTapGetStarted()
        didTapGetStarted?()
    }

    public func tapNoThanks() {
        loggingDelegate?.discoverAnnouncementDidTapNoThanks()
        dismiss()
        didTapNoThanks?()
    }

    private func dismiss() {
        try? dataController.markAnnouncementDismissed()
        isVisible = false
        didDismiss?()
    }
}
