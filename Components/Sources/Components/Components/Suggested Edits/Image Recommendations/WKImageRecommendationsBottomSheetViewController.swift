import UIKit
import WKData

final public class WKImageRecommendationsBottomSheetViewController: WKCanvasViewController {

    // MARK: Properties

    public var viewModel: WKImageRecommendationsViewModel

    // MARK: Lifecycle

    public init(viewModel: WKImageRecommendationsViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let bottomViewModel = populateImageSheetRecommendationViewModel(for: viewModel.currentRecommendation?.imageData) {
            let bottomSheetView = WKImageRecommendationBottomSheetView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), viewModel: bottomViewModel)
            bottomSheetView.delegate = self
            addComponent(bottomSheetView, pinToEdges: true)
        }
    }

    // MARK: Methods

    private func populateImageSheetRecommendationViewModel(for image: WKImageRecommendationData?) -> WKImageRecommendationBottomSheetViewModel? {

        if let image {
            let viewModel = WKImageRecommendationBottomSheetViewModel(
                pageId: image.pageId,
                headerTitle: viewModel.localizedStrings.bottomSheetTitle,
                imageThumbnail: UIImage(),
                imageLink: image.fullUrl,
                thumbLink: image.thumbUrl,
                imageTitle: image.filename,
                imageDescription: image.description,
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
    func goToImageCommonsPage() {

    }
    
    func didTapYesButton() {

    }

    func didTapNoButton() {

    }

    func didTapSkipButton() {
        self.dismiss(animated: true) {
            self.viewModel.next {

            }
        }
    }
}
