import UIKit
import WMFData
import WMFComponents

@MainActor
final class ReadingChallengeAnnouncementCoordinator: NSObject, Coordinator {
    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFFeatureAnnouncementViewModel(
            title: WMFLocalizedString("reading-challenge-announcement-title", value: "Reading Challenge 2026", comment: "Title for the reading challenge 2026 feature announcement."),
            body: WMFLocalizedString("reading-challenge-announcement-body", value: "Read articles every day and build a 25-day streak. Start your challenge today!", comment: "Body text for the reading challenge 2026 feature announcement."),
            primaryButtonTitle: WMFLocalizedString("reading-challenge-announcement-cta", value: "Learn more", comment: "Primary button title for the reading challenge 2026 feature announcement."),
            image: WMFIcon.addPhoto,
            primaryButtonAction: { [weak self] in
                self?.markSeen()
            },
            closeButtonAction: { [weak self] in
                self?.markSeen()
            }
        )

        let viewController = WMFFeatureAnnouncementViewController(viewModel: viewModel)

        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("readingChallengeAnnouncement")) { context in
                return context.maximumDetentValue * 0.65
            }
            sheet.detents = [customDetent, .large()]
            sheet.selectedDetentIdentifier = customDetent.identifier
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(viewController, animated: true)
        return true
    }

    private func markSeen() {
        Task {
            await WMFActivityTabDataController.shared.setHasSeenFullPageAnnouncement()
        }
    }
}

extension WMFActivityTabDataController {
    func setHasSeenFullPageAnnouncement() {
        hasSeenFullPageReadingChallengeAnnouncement2026 = true
    }
}
