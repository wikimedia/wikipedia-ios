import Foundation
import SwiftUI

fileprivate final class WKImageRecommendationsHostingViewController: WKComponentHostingController<WKImageRecommendationsView> {

    init(viewModel: WKImageRecommendationsViewModel) {
        super.init(rootView: WKImageRecommendationsView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

public final class WKImageRecommendationsViewController: WKCanvasViewController {
    
    // MARK: - Properties

    fileprivate let hostingViewController: WKImageRecommendationsHostingViewController

    public init(viewModel: WKImageRecommendationsViewModel) {
        self.hostingViewController = WKImageRecommendationsHostingViewController(viewModel: viewModel)
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
        
         addComponent(hostingViewController, pinToEdges: true)
    }
}
