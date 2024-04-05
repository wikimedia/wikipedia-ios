import SwiftUI
import UIKit
import WKData
import Combine

public protocol WKImageRecommendationsDelegate: AnyObject {
    func imageRecommendationsUserDidTapViewArticle(project: WKProject, title: String)
    func imageRecommendationsUserDidTapImageLink(commonsURL: URL)
    func imageRecommendationsUserDidTapImage(project: WKProject, data: WKImageRecommendationsViewModel.WKImageRecommendationData, presentingVC: UIViewController)
    func imageRecommendationsUserDidTapInsertImage(project: WKProject, title: String, with imageData: WKImageRecommendationsViewModel.WKImageRecommendationData)
    func imageRecommendationsUserDidTapLearnMore(url: URL?)
    func imageRecommendationsUserDidTapTutorial()
    func imageRecommendationsUserDidTapReportIssue()
}

fileprivate final class WKImageRecommendationsHostingViewController: WKComponentHostingController<WKImageRecommendationsView> {

    init(viewModel: WKImageRecommendationsViewModel, delegate: WKImageRecommendationsDelegate) {
        super.init(rootView: WKImageRecommendationsView(viewModel: viewModel, viewArticleAction: { [weak delegate] title in
            delegate?.imageRecommendationsUserDidTapViewArticle(project: viewModel.project, title: title)
        }))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

public final class WKImageRecommendationsViewController: WKCanvasViewController {

    // MARK: - Properties

    fileprivate let hostingViewController: WKImageRecommendationsHostingViewController
    private weak var delegate: WKImageRecommendationsDelegate?
    @ObservedObject private var viewModel: WKImageRecommendationsViewModel
    private var imageRecommendationBottomSheetController: WKImageRecommendationsBottomSheetViewController
    private var cancellables = Set<AnyCancellable>()
    private var regularSizeClass: Bool {
        return traitCollection.horizontalSizeClass == .regular &&
        traitCollection.horizontalSizeClass == .regular ? true : false
    }

    private var overflowMenu: UIMenu {

        let learnMore = UIAction(title: "Learn more", image: UIImage(systemName: "info.circle"), handler: { [weak self] _ in
            self?.goToFAQ()
        })
        let tutorial = UIAction(title: "Learn more", image: UIImage(systemName: "lightbulb.min"), handler: { [weak self] _ in
            self?.showTutorial()
        })

        let reportIssues = UIAction(title: "Problems", image: UIImage(systemName: "flag"), handler: { [weak self] _ in
            self?.reportIssue()
        })

        let menuItems: [UIMenuElement] = [learnMore, tutorial, reportIssues]

        return UIMenu(title: String(), children: menuItems)
    }

    // MARK: Lifecycle

	private let dataController = WKImageRecommendationsDataController()

    public init(viewModel: WKImageRecommendationsViewModel, delegate: WKImageRecommendationsDelegate) {
        self.hostingViewController = WKImageRecommendationsHostingViewController(viewModel: viewModel, delegate: delegate)
        self.delegate = delegate
        self.viewModel = viewModel
        self.imageRecommendationBottomSheetController = WKImageRecommendationsBottomSheetViewController(viewModel: viewModel, delegate: delegate)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.localizedStrings.title
        navigationItem.backButtonDisplayMode = .generic
        setupOverflowMenu()
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bindViewModel()
        presentOnboardingIfNecessary()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        imageRecommendationBottomSheetController.dismiss(animated: true)
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }

    // MARK: Private methods

    private func setupOverflowMenu() {
        let rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: overflowMenu)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        rightBarButtonItem.tintColor = theme.link
    }

    private func presentModalView() {
        if regularSizeClass {
            presentImageRecommendationPopover()
        } else {
            presentImageRecommendationBottomSheet()
        }
    }

    private func presentImageRecommendationBottomSheet() {
        imageRecommendationBottomSheetController.isModalInPresentation = true
        if let bottomSheet = imageRecommendationBottomSheetController.sheetPresentationController {
            bottomSheet.detents = [.medium(), .large()]
            bottomSheet.largestUndimmedDetentIdentifier = .medium
            bottomSheet.prefersGrabberVisible = true
            bottomSheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        navigationController?.present(imageRecommendationBottomSheetController, animated: true)
    }

    private func presentImageRecommendationPopover() {
        imageRecommendationBottomSheetController.isModalInPresentation = true
        if let popover = imageRecommendationBottomSheetController.popoverPresentationController {
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
        }
        navigationController?.present(imageRecommendationBottomSheetController, animated: true)
    }

    private func presentOnboardingIfNecessary() {
        guard !dataController.hasPresentedOnboardingModal else {
            return
        }

        let firstItem = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: WKSFSymbolIcon.for(symbol: .photoOnRectangleAngled), title: viewModel.localizedStrings.onboardingStrings.firstItemTitle, subtitle: viewModel.localizedStrings.onboardingStrings.firstItemBody, fillIconBackground: true)

        let secondItem = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: WKSFSymbolIcon.for(symbol: .plusForwardSlashMinus), title: viewModel.localizedStrings.onboardingStrings.secondItemTitle, subtitle: viewModel.localizedStrings.onboardingStrings.secondItemBody, fillIconBackground: true)

        let thirdItem = WKOnboardingViewModel.WKOnboardingCellViewModel(icon: WKIcon.commons, title: viewModel.localizedStrings.onboardingStrings.thirdItemTitle, subtitle: viewModel.localizedStrings.onboardingStrings.thirdItemBody, fillIconBackground: true)

        let onboardingViewModel = WKOnboardingViewModel(title: viewModel.localizedStrings.onboardingStrings.title, cells: [firstItem, secondItem, thirdItem], primaryButtonTitle: viewModel.localizedStrings.onboardingStrings.continueButton, secondaryButtonTitle: viewModel.localizedStrings.onboardingStrings.learnMoreButton)

        let onboardingController = WKOnboardingViewController(viewModel: onboardingViewModel)
        onboardingController.hostingController.delegate = self
        present(onboardingController, animated: true, completion: {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        })

        dataController.hasPresentedOnboardingModal = true
    }

    private func bindViewModel() {
        viewModel.$loading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.presentModalView()
                }
            }
            .store(in: &cancellables)
    }

    private func showTutorial() {
        delegate?.imageRecommendationsUserDidTapTutorial()
    }

    private func goToFAQ() {
        delegate?.imageRecommendationsUserDidTapLearnMore(url: viewModel.learnMoreURL)
    }

    private func reportIssue() {
        delegate?.imageRecommendationsUserDidTapReportIssue()
    }
}

extension WKImageRecommendationsViewController: WKOnboardingViewDelegate {

	public func didClickPrimaryButton() {
		presentedViewController?.dismiss(animated: true)
	}
	
	public func didClickSecondaryButton() {
        guard let url = viewModel.learnMoreURL else {
			return
		}

		UIApplication.shared.open(url)
	}

}
