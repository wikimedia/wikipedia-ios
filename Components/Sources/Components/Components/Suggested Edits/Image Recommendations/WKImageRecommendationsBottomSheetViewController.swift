import UIKit
import WKData

final public class WKImageRecommendationsBottomSheetViewController: WKCanvasViewController {

    // MARK: Properties

    public var viewModel: WKImageRecommendationsViewModel
    weak var delegate: WKImageRecommendationsDelegate?

    // MARK: Lifecycle

    public init(viewModel: WKImageRecommendationsViewModel, delegate: WKImageRecommendationsDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let bottomViewModel = populateImageSheetRecommendationViewModel(for: viewModel.currentRecommendation?.imageData) {
            let bottomSheetView = WKImageRecommendationBottomSheetView(frame: UIScreen.main.bounds, viewModel: bottomViewModel)
            bottomSheetView.delegate = self
            addComponent(bottomSheetView, pinToEdges: true)
        }
    }

    // MARK: Methods

    private func populateImageSheetRecommendationViewModel(for image: WKImageRecommendationsViewModel.WKImageRecommendationData?) -> WKImageRecommendationBottomSheetViewModel? {

        if let image {
            let viewModel = WKImageRecommendationBottomSheetViewModel(
                pageId: image.pageId,
                headerTitle: viewModel.localizedStrings.bottomSheetTitle,
                imageThumbnail: image.uiImage,
                imageLink: image.fullUrl,
                thumbLink: image.thumbUrl,
                imageTitle: image.filename,
                imageDescription: image.description, 
                reason: image.reason,
                yesButtonTitle: viewModel.localizedStrings.yesButtonTitle,
                noButtonTitle: viewModel.localizedStrings.noButtonTitle,
                notSureButtonTitle: viewModel.localizedStrings.notSureButtonTitle
            )
            return viewModel
        }
        return nil
    }

}
extension WKImageRecommendationsBottomSheetViewController: WKImageRecommendationsToolbarViewDelegate {
    func goToGallery() {
        guard let currentRecommendation = viewModel.currentRecommendation else {
            return
        }
        
        delegate?.imageRecommendationsUserDidTapImage(project: viewModel.project, data: currentRecommendation.imageData, presentingVC: self)
    }
    
    func goToImageCommonsPage() {

        guard let currentRecommendation = viewModel.currentRecommendation,
        let url = URL(string: currentRecommendation.imageData.descriptionURL) else {
            return
        }
        
        delegate?.imageRecommendationsUserDidTapImageLink(commonsURL: url)
    }
    
    func didTapYesButton() {
        if let imageData = viewModel.currentRecommendation?.imageData {
            self.dismiss(animated: true) {
                self.delegate?.imageRecommendationsUserDidTapInsertImage(with: imageData)
            }
        }
    }

    func didTapNoButton() {
		let surveyView = WKImageRecommendationsSurveyView(
			viewModel: WKImageRecommendationsSurveyViewModel(localizedStrings: viewModel.localizedStrings.surveyLocalizedStrings),
			cancelAction: { [weak self] in
				self?.dismiss(animated: true)
			},
			submitAction: { [weak self] reasons in
				self?.dismiss(animated: true)
		})

		let hostedView = WKComponentHostingController(rootView: surveyView)
		present(hostedView, animated: true)
    }

    func didTapSkipButton() {
        self.dismiss(animated: true) {
            self.viewModel.next {

            }
        }
    }
}
