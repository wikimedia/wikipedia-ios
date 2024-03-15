import Foundation
import SwiftUI
import WKData

public protocol WKImageRecommendationsDelegate: AnyObject {
    func imageRecommendationsUserDidTapViewArticle(project: WKProject, title: String)
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
    private let viewModel: WKImageRecommendationsViewModel

	private let dataController = WKImageRecommendationsDataController()

    public init(viewModel: WKImageRecommendationsViewModel, delegate: WKImageRecommendationsDelegate) {
        self.hostingViewController = WKImageRecommendationsHostingViewController(viewModel: viewModel, delegate: delegate)
        self.delegate = delegate
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presentOnboardingIfNecessary()
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

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.localizedStrings.title
        addComponent(hostingViewController, pinToEdges: true)
    }
}

extension WKImageRecommendationsViewController: WKOnboardingViewDelegate {

	public func didClickPrimaryButton() {
		presentedViewController?.dismiss(animated: true)
	}
	
	public func didClickSecondaryButton() {
		guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits#Add_an_image") else {
			return
		}

		UIApplication.shared.open(url)
	}

}
