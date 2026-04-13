import UIKit
import WMFComponents

final class ReadingChallengeWidgetAnnouncementCoordinator {

    private weak var presentingViewController: UIViewController?

    init(presentingViewController: UIViewController & WMFFeatureAnnouncing) {
        self.presentingViewController = presentingViewController
    }

    func start() {
        guard let presenting = presentingViewController else { return }

        let controller = WMFFeatureAnnouncementViewController(viewModel: makeViewModel())

        if let sheet = controller.sheetPresentationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                sheet.detents = [.large()]
                controller.preferredContentSize = CGSize(width: 640, height: 720)
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        controller.modalPresentationStyle = .pageSheet
        presenting.present(controller, animated: true)
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

