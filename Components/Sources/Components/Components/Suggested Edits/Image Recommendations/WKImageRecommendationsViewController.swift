import Foundation
import SwiftUI
import UIKit
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
    private var imageRecommendationBottomSheet: WKImageRecommendationBottomSheetViewController?

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

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.localizedStrings.title
        if let imageData = viewModel.currentRecommendation?.imageData {
            imageRecommendationBottomSheet = WKImageRecommendationBottomSheetViewController(viewModel: viewModel, imageData: imageData)
        }
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let vc = imageRecommendationBottomSheet {
            if let bottomViewController = vc.sheetPresentationController {
                bottomViewController.detents = [.medium(), .large()]
                bottomViewController.largestUndimmedDetentIdentifier = .medium
                bottomViewController.prefersGrabberVisible = true
                bottomViewController.preferredCornerRadius = 24
            }

            navigationController?.present(vc, animated: true)

        }
    }
}
