import UIKit
import WMFData

/// Shared Year in Review announcement presentation for the feed surfaces.
///
/// `ExploreViewController` owns it while the Explore feed is the visible feed. In the Home tab that
/// is not always true: the embedded Explore feed is only on screen while the Community segment is
/// selected, and with home phase 2 enabled it is never created at all. `HomeViewController` covers
/// those cases, so the announcement still lands on the first relevant app open.
///
/// Both surfaces run the same guards and mark the same once-per-user flag, so moving between them
/// cannot produce a second showing.
@MainActor
protocol YearInReviewAnnouncementPresenting: UIViewController {
    var yirDataController: WMFYearInReviewDataController? { get }

    /// The coordinator that presents the announcement. Each surface keeps its own, tied to its
    /// navigation controller.
    var yirAnnouncementCoordinator: YearInReviewCoordinator? { get }

    /// Identifies the surface in the intro slide's logging.
    var yirAnnouncementLoggingID: String { get }
}

extension YearInReviewAnnouncementPresenting {

    /// True when this session was started by a deep link. Modals are suppressed in that case so we
    /// do not interrupt whatever the link was pointing at.
    var didOpenAppFromExternalLink: Bool {
#if !TEST
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
           sceneDelegate.didOpenAppFromExternalLink {
            return true
        }
#endif
        return false
    }

    func needsYearInReviewAnnouncement() -> Bool {

        if UIDevice.current.userInterfaceIdiom == .pad && (navigationController?.navigationBar.isHidden ?? false) {
            return false
        }

        // Same rule as the article surface: no announcement during a deep linked session.
        guard !didOpenAppFromExternalLink else {
            return false
        }

        guard let yirDataController else {
            return false
        }

        guard yirDataController.shouldShowYearInReviewFeatureAnnouncement() else {
            return false
        }

        // Never present over an existing modal — doing so crashes with "already presenting". The
        // navigation controller is checked too: Explore and the Home tab share one, and with the
        // developer flag on (which skips the once-per-user state) both could otherwise try.
        guard presentedViewController == nil, navigationController?.presentedViewController == nil else {
            return false
        }

        guard isViewLoaded && view.window != nil else {
            return false
        }

        return true
    }

    func presentYearInReviewAnnouncement() {
        guard let yirDataController else {
            return
        }

        // TODO: 2026 — swap `yirAnnouncementCoordinator` for the 2026 coordinator. It needs to know
        // it was launched from the announcement so that slide 0 is included and the exit toast fires.
        yirAnnouncementCoordinator?.setupForFeatureAnnouncement(introSlideLoggingID: yirAnnouncementLoggingID)
        yirAnnouncementCoordinator?.start()

        // Marked as soon as it is presented, so a force quit on slide 0 does not earn a second showing.
        yirDataController.hasPresentedYiRFeatureAnnouncement = true
    }
}
