import UIKit
import WMFComponents

final class ReadingChallengeWidgetAnnouncementCoordinator {

    private weak var presentingViewController: (UIViewController & WMFFeatureAnnouncing)?

    init(presentingViewController: UIViewController & WMFFeatureAnnouncing) {
        self.presentingViewController = presentingViewController
    }

    func start() {
        guard let presenting = presentingViewController else { return }
        presenting.announceFeature(
            viewModel: makeViewModel(),
            sourceView: presenting.view,
            sourceRect: CGRect(origin: presenting.view.center, size: .zero),
            barButtonItem: nil
        )
    }

    private func makeViewModel() -> WMFFeatureAnnouncementViewModel {
        WMFFeatureAnnouncementViewModel(
            title: WMFLocalizedString(
                "reading-challenge-widget-announcement-title",
                value: "25-day reading challenge widget available",
                comment: "Title for the reading challenge widget announcement sheet."
            ),
            body: WMFLocalizedString(
                "reading-challenge-widget-announcement-body",
                value: "Baby Globe is cheering you on. Add the Reading Challenge widget to track your progress from your homescreen.",
                comment: "Body text for the reading challenge widget announcement sheet."
            ),
            primaryButtonTitle: CommonStrings.gotItButtonTitle,
            image: UIImage(named: "readingChallengeWidget"),
            backgroundImage: UIImage(named: "readingChallengeBackground"),
            backgroundImageHeight: 220,
            primaryButtonAction: {},
            closeButtonAction: nil
        )
    }
}
