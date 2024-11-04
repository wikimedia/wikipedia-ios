import WMF
import SwiftUI
import CocoaLumberjackSwift
import WMFComponents
import WMFData
import UIKit
import Foundation

fileprivate final class WMFYearInReviewHostingController: WMFComponentHostingController<WMFYearInReviewView> {
    init(viewModel: WMFYearInReviewViewModel) {
        super.init(rootView: WMFYearInReviewView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WMFYearInReviewViewController: WMFCanvasViewController {
    private let hostingViewController: WMFYearInReviewHostingController
    private let viewModel: WMFYearInReviewViewModel
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
        self.hostingViewController = WMFYearInReviewHostingController(viewModel: viewModel)
        super.init()
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
