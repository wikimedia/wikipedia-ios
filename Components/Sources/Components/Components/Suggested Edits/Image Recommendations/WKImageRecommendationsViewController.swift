import SwiftUI
import UIKit
import WKData
import Combine

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
    @ObservedObject private var viewModel: WKImageRecommendationsViewModel
    private var imageRecommendationBottomSheetController: WKImageRecommendationsBottomSheetViewController
    private var cancellables = Set<AnyCancellable>()
    private var regularSizeClass: Bool {
        return traitCollection.horizontalSizeClass == .regular &&
        traitCollection.horizontalSizeClass == .regular ? true : false
    }

    // MARK: Lifecycle

    public init(viewModel: WKImageRecommendationsViewModel, delegate: WKImageRecommendationsDelegate) {
        self.hostingViewController = WKImageRecommendationsHostingViewController(viewModel: viewModel, delegate: delegate)
        self.delegate = delegate
        self.viewModel = viewModel
        self.imageRecommendationBottomSheetController = WKImageRecommendationsBottomSheetViewController(viewModel: viewModel)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
       
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.localizedStrings.title
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bindViewModel()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        if imageRecommendationBottomSheetController.sheetPresentationController != nil {
            imageRecommendationBottomSheetController.isModalInPresentation = false
        }
        imageRecommendationBottomSheetController.dismiss(animated: true)
    }

    // MARK: Private methods

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

    private func bindViewModel() {
        viewModel.$loading
            .receive(on: RunLoop.main)
            .sink { [weak self] presentBottomSheet in
                if !presentBottomSheet {
                    self?.presentModalView()
                }
            }
            .store(in: &cancellables)
    }
}

