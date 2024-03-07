import UIKit
import WKData

final public class WKImageRecommendationsBottomSheetViewController: WKCanvasViewController {

    public var viewModel: WKImageRecommendationsViewModel

    public init(viewModel: WKImageRecommendationsViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if let bottomViewModel = populateImageSheetRecViewModel(for: viewModel.currentRecommendation?.imageData) {
            let newView = WKImageRecommendationBottomSheetView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), viewModel: bottomViewModel)
            addComponent(newView, pinToEdges: true)
        }

    }

    public override func loadView() {
        super.loadView()


    }

    func populateImageSheetRecViewModel(for image: ImageRecommendationData?) -> WKImageRecommendationBottomSheetViewModel? {

        if let image {
            let viewModel = WKImageRecommendationBottomSheetViewModel(
                pageId: image.pageId,
                headerTitle: viewModel.localizedStrings.bottomSheetTitle,
                headerIcon: UIImage(),
                image: UIImage(), // populatewithThumb and not init
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
