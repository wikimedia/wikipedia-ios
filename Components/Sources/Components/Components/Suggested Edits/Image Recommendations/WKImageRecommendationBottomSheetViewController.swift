import UIKit
import WKData

final public class WKBottomSheetViewController: WKCanvasViewController {

    public var viewModel: WKImageRecommendationBottomSheetViewModel

    public init(viewModel: WKImageRecommendationBottomSheetViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()


    }

}
